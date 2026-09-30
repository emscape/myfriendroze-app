import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myfriendroze_admin/providers/saved_location_provider.dart';
import 'package:myfriendroze_admin/services/firestore_service.dart';
import 'package:myfriendroze_admin/widgets/saved_location_autocomplete.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  late TextEditingController controller;

  setUp(() {
    FirestoreService.setFirestoreInstance(FakeFirebaseFirestore());
    controller = TextEditingController();
  });

  tearDown(() {
    controller.dispose();
  });

  Future<SavedLocationProvider> pumpWithLocations(
    WidgetTester tester, {
    required List<({String name, String address})> locations,
  }) async {
    final provider = SavedLocationProvider();
    for (final loc in locations) {
      await provider.addLocation(name: loc.name, address: loc.address);
    }
    provider.loadLocations();
    await tester.pumpWidget(
      ChangeNotifierProvider<SavedLocationProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: SavedLocationAutocomplete(controller: controller, labelText: 'Location'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return provider;
  }

  testWidgets('tapping the empty field shows all saved locations', (tester) async {
    await pumpWithLocations(tester, locations: [
      (name: 'Jackalope Pasadena', address: '123 Colorado Blvd'),
      (name: 'Common Space Brewing', address: '456 El Segundo Blvd'),
    ]);

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    expect(find.text('Jackalope Pasadena'), findsOneWidget);
    expect(find.text('Common Space Brewing'), findsOneWidget);
  });

  testWidgets('typing filters the dropdown to matching saved locations', (tester) async {
    await pumpWithLocations(tester, locations: [
      (name: 'Jackalope Pasadena', address: '123 Colorado Blvd'),
      (name: 'Common Space Brewing', address: '456 El Segundo Blvd'),
    ]);

    await tester.enterText(find.byType(TextFormField), 'Jackalope');
    await tester.pumpAndSettle();

    expect(find.text('Jackalope Pasadena'), findsOneWidget);
    expect(find.text('Common Space Brewing'), findsNothing);
  });

  testWidgets('selecting a saved location fills the field with its address', (tester) async {
    await pumpWithLocations(tester, locations: [
      (name: 'Jackalope Pasadena', address: '123 Colorado Blvd'),
    ]);

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jackalope Pasadena'));
    await tester.pumpAndSettle();

    expect(controller.text, '123 Colorado Blvd');
  });

  testWidgets('allows typing a brand-new address with no saved-location match', (tester) async {
    await pumpWithLocations(tester, locations: []);

    await tester.enterText(find.byType(TextFormField), '789 One-Off Market St');
    await tester.pumpAndSettle();

    expect(controller.text, '789 One-Off Market St');
    expect(tester.takeException(), isNull);
  });
}
