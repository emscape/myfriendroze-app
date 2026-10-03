import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myfriendroze_admin/providers/product_provider.dart';
import 'package:myfriendroze_admin/screens/products/add_product_screen.dart';
import 'package:myfriendroze_admin/services/shipping_estimate_service.dart';
import 'package:myfriendroze_admin/widgets/shipping_estimate_panel.dart';

const _box = ParcelInput(weightGrams: 1360.78, lengthIn: 12, widthIn: 10, heightIn: 8);

final _estimate = ShippingEstimate.fromMap({
  'quotes': [
    {'label': 'Los Angeles', 'zip': '90012', 'amount': 5.98},
    {'label': 'New York', 'zip': '10001', 'amount': 11.3},
    {'label': 'Alaska / Hawaii', 'zip': '96813', 'amount': 15.75},
  ],
  'suggestedShipping': 14,
  'testMode': false,
});

class FakeEstimator implements ShippingEstimator {
  FakeEstimator({this.result, this.error});

  final ShippingEstimate? result;
  final Object? error;
  final List<ParcelInput> calls = [];

  @override
  Future<ShippingEstimate> estimate(ParcelInput parcel) async {
    calls.add(parcel);
    if (error != null) throw error!;
    return result!;
  }
}

Future<void> pumpPanel(WidgetTester tester, FakeEstimator estimator, {ParcelInput? parcel = _box}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: ShippingEstimatePanel(estimator: estimator, readParcel: () => parcel),
    ),
  ));
}

void main() {
  group('ShippingEstimatePanel', () {
    testWidgets('shows each quote and the suggested amount to build into the price', (tester) async {
      final estimator = FakeEstimator(result: _estimate);
      await pumpPanel(tester, estimator);

      await tester.tap(find.text('Estimate shipping'));
      await tester.pumpAndSettle();

      expect(estimator.calls, hasLength(1));
      expect(find.text('Los Angeles: \$5.98'), findsOneWidget);
      expect(find.text('New York: \$11.30'), findsOneWidget);
      expect(find.text('Alaska / Hawaii: \$15.75'), findsOneWidget);
      expect(find.text('Suggested shipping to build into the price: \$14'), findsOneWidget);
      expect(find.textContaining('test'), findsNothing);
    });

    testWidgets('says when the prices are from Shippo test mode', (tester) async {
      final testEstimate = ShippingEstimate.fromMap({
        'quotes': <Map<String, dynamic>>[],
        'suggestedShipping': 14,
        'testMode': true,
      });
      await pumpPanel(tester, FakeEstimator(result: testEstimate));

      await tester.tap(find.text('Estimate shipping'));
      await tester.pumpAndSettle();

      expect(find.textContaining('test prices'), findsOneWidget);
    });

    testWidgets('asks for the weight and box size instead of calling when they are missing', (tester) async {
      final estimator = FakeEstimator(result: _estimate);
      await pumpPanel(tester, estimator, parcel: null);

      await tester.tap(find.text('Estimate shipping'));
      await tester.pumpAndSettle();

      expect(estimator.calls, isEmpty);
      expect(find.text('Enter the weight and all three box sizes first.'), findsOneWidget);
    });

    testWidgets('shows the error when the estimate fails', (tester) async {
      await pumpPanel(tester, FakeEstimator(error: Exception('boom')));

      await tester.tap(find.text('Estimate shipping'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't get a shipping estimate. Try again in a moment."), findsOneWidget);
    });

    testWidgets('hides Firebase\'s own error text, like a bare "internal"', (tester) async {
      await pumpPanel(
        tester,
        FakeEstimator(error: FirebaseFunctionsException(code: 'internal', message: 'internal')),
      );

      await tester.tap(find.text('Estimate shipping'));
      await tester.pumpAndSettle();

      expect(find.text('internal'), findsNothing);
      expect(find.text("Couldn't get a shipping estimate. Try again in a moment."), findsOneWidget);
    });

    testWidgets('shows the message the estimate function wrote for bad input', (tester) async {
      await pumpPanel(
        tester,
        FakeEstimator(
          error: FirebaseFunctionsException(code: 'invalid-argument', message: 'Box is too large to ship'),
        ),
      );

      await tester.tap(find.text('Estimate shipping'));
      await tester.pumpAndSettle();

      expect(find.text('Box is too large to ship'), findsOneWidget);
    });
  });

  testWidgets('the product form estimates from its weight and shipping box fields', (tester) async {
    final estimator = FakeEstimator(result: _estimate);
    await tester.pumpWidget(
      ChangeNotifierProvider<ProductProvider>(
        create: (_) => ProductProvider(),
        child: MaterialApp(home: AddProductScreen(shippingEstimator: estimator)),
      ),
    );

    Future<void> enter(String label, String text) async {
      final field = find.widgetWithText(TextFormField, label);
      await tester.ensureVisible(field);
      await tester.enterText(field, text);
    }

    await enter('Weight (lbs)', '3');
    await enter('Weight (oz)', '0');
    await enter('Box height (in)', '8');
    await enter('Box width (in)', '10');
    await enter('Box depth (in)', '12');
    await tester.ensureVisible(find.text('Estimate shipping'));
    await tester.tap(find.text('Estimate shipping'));
    await tester.pumpAndSettle();

    expect(estimator.calls, hasLength(1));
    final parcel = estimator.calls.single;
    expect(parcel.weightGrams, closeTo(1360.78, 0.01));
    expect([parcel.lengthIn, parcel.widthIn, parcel.heightIn], [12, 10, 8]);
    expect(find.text('Suggested shipping to build into the price: \$14'), findsOneWidget);
  });

  for (final (label, bad) in [('Weight (lbs)', 'NaN'), ('Box height (in)', 'Infinity')]) {
    testWidgets('the product form treats "$bad" in $label as missing instead of calling', (tester) async {
      final estimator = FakeEstimator(result: _estimate);
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => ProductProvider(),
          child: MaterialApp(home: AddProductScreen(shippingEstimator: estimator)),
        ),
      );

      final values = {
        'Weight (lbs)': '3',
        'Weight (oz)': '0',
        'Box height (in)': '8',
        'Box width (in)': '10',
        'Box depth (in)': '12',
        label: bad,
      };
      for (final entry in values.entries) {
        final field = find.widgetWithText(TextFormField, entry.key);
        await tester.ensureVisible(field);
        await tester.enterText(field, entry.value);
      }
      await tester.ensureVisible(find.text('Estimate shipping'));
      await tester.tap(find.text('Estimate shipping'));
      await tester.pumpAndSettle();

      expect(estimator.calls, isEmpty);
      expect(find.text('Enter the weight and all three box sizes first.'), findsOneWidget);
    });
  }
}
