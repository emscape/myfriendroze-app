// Stock counts for plants: the admin-side half of the site's stock
// tracking. The site reads `stockQuantity` from the product doc, checkout
// refuses more than that (firebase/functions/lib/pricing.js in the
// myfriendroze repo), and the Stripe webhook counts it down after payment
// (lib/stockCounts.js there).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:provider/provider.dart';

import 'package:myfriendroze_admin/models/product.dart';
import 'package:myfriendroze_admin/models/product_category.dart';
import 'package:myfriendroze_admin/providers/product_provider.dart';
import 'package:myfriendroze_admin/screens/products/add_product_screen.dart';
import 'package:myfriendroze_admin/services/firestore_service.dart';
import 'package:myfriendroze_admin/services/storage_service.dart';
import 'package:myfriendroze_admin/utils/stock_count.dart';

Product _product({ProductCategory? category, int? stockQuantity}) => Product(
      id: 'p1',
      title: 'Aloe',
      description: 'A small aloe',
      price: 8,
      weight: 300,
      category: category,
      stockQuantity: stockQuantity,
      imageUrls: const [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('Product.stockQuantity', () {
    test('round-trips through Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('products').doc('p1');
      await docRef.set(_product(stockQuantity: 7).toFirestore());

      expect(Product.fromFirestore(await docRef.get()).stockQuantity, 7);
    });

    test('is null for products saved before stock counts existed', () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('products').doc('p1');
      await docRef.set({'title': 'Old Bowl', 'price': 40});

      expect(Product.fromFirestore(await docRef.get()).stockQuantity, isNull);
    });

    // Product saves are merge updates, so clearing a count needs an
    // explicit null rather than an omitted key.
    test('writes an explicit null when untracked', () {
      final data = _product().toFirestore();

      expect(data.containsKey('stockQuantity'), isTrue);
      expect(data['stockQuantity'], isNull);
    });

    test('copyWith sets, keeps, and clears the count', () {
      final tracked = _product().copyWith(stockQuantity: 4);

      expect(tracked.stockQuantity, 4);
      expect(tracked.copyWith(title: 'Big Aloe').stockQuantity, 4);
      expect(tracked.copyWith(clearStockQuantity: true).stockQuantity, isNull);
    });
  });

  group('stockUpdateFor', () {
    test('a plant with a count saves it, in stock when above 0', () {
      final update = stockUpdateFor(ProductCategory.plant, ' 5 ');

      expect(update.stockQuantity, 5);
      expect(update.inStock, isTrue);
    });

    test('a plant with 0 saves it as sold out', () {
      final update = stockUpdateFor(ProductCategory.plant, '0');

      expect(update.stockQuantity, 0);
      expect(update.inStock, isFalse);
    });

    test('a plant left blank is untracked, and its in-stock state is left alone', () {
      final update = stockUpdateFor(ProductCategory.plant, '');

      expect(update.stockQuantity, isNull);
      expect(update.inStock, isNull);
    });

    test('pottery and other pieces are never tracked, whatever the field held', () {
      for (final category in [ProductCategory.pottery, ProductCategory.other, null]) {
        final update = stockUpdateFor(category, '5');

        expect(update.stockQuantity, isNull);
        expect(update.inStock, isNull);
      }
    });
  });

  // What an edit saves: the form's stock field applied to the product
  // being edited.
  group('applyStockUpdate', () {
    Product editAs(ProductCategory category, String text, {int? stock = 5, bool inStock = true}) =>
        applyStockUpdate(
          _product(category: ProductCategory.plant, stockQuantity: stock).copyWith(inStock: inStock),
          stockUpdateFor(category, text),
        );

    test('a new count replaces the old one and puts the plant in stock', () {
      final saved = editAs(ProductCategory.plant, '3', inStock: false);

      expect(saved.stockQuantity, 3);
      expect(saved.inStock, isTrue);
    });

    test('a count of 0 is saved and marks the plant sold out', () {
      final saved = editAs(ProductCategory.plant, '0');

      expect(saved.stockQuantity, 0);
      expect(saved.inStock, isFalse);
    });

    test('a blank count stops tracking and leaves in-stock as it was', () {
      final saved = editAs(ProductCategory.plant, '', inStock: false);

      expect(saved.stockQuantity, isNull);
      expect(saved.inStock, isFalse);
    });

    test('switching away from Plant clears the count', () {
      final saved = editAs(ProductCategory.pottery, '5');

      expect(saved.stockQuantity, isNull);
      expect(saved.inStock, isTrue);
    });
  });

  group('ProductProvider.addProduct', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      FirestoreService.setFirestoreInstance(fakeFirestore);
      StorageService.setStorageInstance(MockFirebaseStorage());
    });

    Future<Map<String, dynamic>> add(StockUpdate update) async {
      final ok = await ProductProvider().addProduct(
        title: 'Aloe',
        description: 'A small aloe',
        price: 8,
        weight: 300,
        category: ProductCategory.plant,
        stockQuantity: update.stockQuantity,
        inStock: update.inStock ?? true,
      );
      expect(ok, isTrue);
      final docs = (await fakeFirestore.collection('products').get()).docs;
      expect(docs, hasLength(1));
      return docs.single.data();
    }

    test("saves a new plant's count, in stock", () async {
      final data = await add(stockUpdateFor(ProductCategory.plant, '6'));

      expect(data['stockQuantity'], 6);
      expect(data['inStock'], isTrue);
    });

    test('saves a new plant with 0 as sold out', () async {
      final data = await add(stockUpdateFor(ProductCategory.plant, '0'));

      expect(data['stockQuantity'], 0);
      expect(data['inStock'], isFalse);
    });

    test('saves a new plant left blank as untracked and in stock', () async {
      final data = await add(stockUpdateFor(ProductCategory.plant, ''));

      expect(data['stockQuantity'], isNull);
      expect(data['inStock'], isTrue);
    });
  });

  group('validateStockCount', () {
    test('accepts blank or a whole number of 0 or more', () {
      for (final ok in ['', '  ', '0', '12']) {
        expect(validateStockCount(ok), isNull, reason: ok);
      }
    });

    test('rejects anything else', () {
      for (final bad in ['-1', '2.5', 'lots']) {
        expect(validateStockCount(bad), isNotNull, reason: bad);
      }
    });
  });

  group('product form', () {
    Future<void> openForm(WidgetTester tester, Product product) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => ProductProvider(),
          child: MaterialApp(home: AddProductScreen(productToEdit: product)),
        ),
      );
    }

    testWidgets('shows the stock count for a plant, prefilled', (tester) async {
      await openForm(tester, _product(category: ProductCategory.plant, stockQuantity: 6));

      expect(find.text(stockCountLabel), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '6'), findsOneWidget);
    });

    testWidgets('has no stock count for a pottery piece', (tester) async {
      await openForm(tester, _product(category: ProductCategory.pottery));

      expect(find.text(stockCountLabel), findsNothing);
    });
  });
}
