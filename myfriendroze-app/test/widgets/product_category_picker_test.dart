// Widget tests for the category picker on the add/edit product form.
//
// New products must choose a category (no default, so a plant is never
// silently filed as pottery). Editing a product that predates the field
// preselects pottery, matching how the site already lists it, so saving
// an unrelated edit backfills the category.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myfriendroze_admin/models/product.dart';
import 'package:myfriendroze_admin/models/product_category.dart';
import 'package:myfriendroze_admin/providers/product_provider.dart';
import 'package:myfriendroze_admin/screens/products/add_product_screen.dart';
import 'package:myfriendroze_admin/widgets/product_category_picker.dart';

Widget _form({Product? productToEdit}) => ChangeNotifierProvider(
      create: (_) => ProductProvider(),
      child: MaterialApp(home: AddProductScreen(productToEdit: productToEdit)),
    );

Product _existing({ProductCategory? category}) => Product(
      id: 'p1',
      title: 'Old Mug',
      description: 'Made before categories existed',
      price: 15,
      weight: 300,
      category: category,
      imageUrls: const [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

String? _selected(WidgetTester tester) {
  final field = tester.widget<DropdownButtonFormField<ProductCategory>>(
    find.byType(DropdownButtonFormField<ProductCategory>),
  );
  return field.initialValue?.value;
}

void main() {
  testWidgets('the add form shows the category picker with nothing chosen',
      (tester) async {
    await tester.pumpWidget(_form());

    expect(find.byType(ProductCategoryPicker), findsOneWidget);
    expect(_selected(tester), isNull);
  });

  testWidgets('submitting a new product without a category shows an error',
      (tester) async {
    await tester.pumpWidget(_form());

    final submit = find.widgetWithText(ElevatedButton, 'Add Product');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Please choose a category'), findsOneWidget);
  });

  testWidgets('each category can be chosen from the picker', (tester) async {
    await tester.pumpWidget(_form());

    final picker = find.byType(DropdownButtonFormField<ProductCategory>);
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pumpAndSettle();

    for (final category in ProductCategory.values) {
      expect(find.text(category.label), findsWidgets);
    }

    await tester.tap(find.text(ProductCategory.plant.label).last);
    await tester.pumpAndSettle();

    final submit = find.widgetWithText(ElevatedButton, 'Add Product');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('Please choose a category'), findsNothing);
  });

  testWidgets('editing a product with no category preselects pottery',
      (tester) async {
    await tester.pumpWidget(_form(productToEdit: _existing()));

    expect(_selected(tester), 'pottery');
  });

  testWidgets('editing a categorised product preselects its category',
      (tester) async {
    await tester.pumpWidget(
        _form(productToEdit: _existing(category: ProductCategory.plant)));

    expect(_selected(tester), 'plant');
  });
}
