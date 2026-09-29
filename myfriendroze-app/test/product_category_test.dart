// Tests for the product category field (pottery / plant / other).
//
// The site (astro/src/lib/product-mapping.js in the myfriendroze repo)
// splits the shop into one listing page per category and treats a missing
// or unrecognised category as pottery, since every product created before
// this field existed is pottery. The app mirrors that: a legacy doc reads
// back as "no category" (null) rather than a guessed value, and the edit
// form is what fills it in.

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:myfriendroze_admin/models/product.dart';
import 'package:myfriendroze_admin/models/product_category.dart';
import 'package:myfriendroze_admin/providers/product_provider.dart';
import 'package:myfriendroze_admin/services/firestore_service.dart';
import 'package:myfriendroze_admin/services/storage_service.dart';

Product _product({ProductCategory? category}) => Product(
      id: 'p1',
      title: 'Bowl',
      description: 'A bowl',
      price: 20,
      weight: 500,
      category: category,
      imageUrls: const [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('ProductCategory.fromValue', () {
    test('maps each stored value to its category', () {
      expect(ProductCategory.fromValue('pottery'), ProductCategory.pottery);
      expect(ProductCategory.fromValue('plant'), ProductCategory.plant);
      expect(ProductCategory.fromValue('other'), ProductCategory.other);
    });

    test('returns null for a missing or unrecognised value', () {
      expect(ProductCategory.fromValue(null), isNull);
      expect(ProductCategory.fromValue(''), isNull);
      expect(ProductCategory.fromValue('jewelry'), isNull);
    });

    test('stored values match the strings the site filters on', () {
      expect(
        ProductCategory.values.map((c) => c.value).toList(),
        ['pottery', 'plant', 'other'],
      );
    });
  });

  group('Product.category', () {
    test('constructor defaults category to null when omitted', () {
      expect(_product().category, isNull);
    });

    test('round-trips a category through Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('products').doc('p1');
      await docRef.set(_product(category: ProductCategory.plant).toFirestore());

      final snapshot = await docRef.get();
      expect(snapshot.data()!['category'], 'plant');
      expect(Product.fromFirestore(snapshot).category, ProductCategory.plant);
    });

    test('fromFirestore reads a legacy doc with no category as null', () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('products').doc('legacy');
      await docRef.set({
        'title': 'Old Mug',
        'description': 'No category field on file',
        'price': 15.0,
        'weight': 300.0,
        'imageUrls': <String>[],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final product = Product.fromFirestore(await docRef.get());
      expect(product.category, isNull);
    });

    test('toFirestore omits category when unset, so an update cannot erase one',
        () {
      expect(_product().toFirestore().containsKey('category'), isFalse);
    });

    test('copyWith sets category independently of other fields', () {
      final updated = _product().copyWith(category: ProductCategory.other);
      expect(updated.category, ProductCategory.other);
      expect(updated.title, 'Bowl');
    });
  });

  group('ProductProvider category writes', () {
    late FakeFirebaseFirestore fakeFirestore;
    late ProductProvider provider;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      FirestoreService.setFirestoreInstance(fakeFirestore);
      StorageService.setStorageInstance(MockFirebaseStorage());
      provider = ProductProvider();
    });

    test('addProduct saves the chosen category', () async {
      final result = await provider.addProduct(
        title: 'String of Pearls',
        description: 'Trailing succulent',
        price: 18,
        weight: 400,
        category: ProductCategory.plant,
      );

      expect(result, isTrue);
      final docs = (await fakeFirestore.collection('products').get()).docs;
      expect(docs, hasLength(1));
      expect(docs.single.data()['category'], 'plant');
    });

    test('updateProduct backfills a category onto a legacy product', () async {
      await fakeFirestore.collection('products').doc('p1').set({
        'title': 'Old Mug',
        'description': 'No category field on file',
        'price': 15.0,
        'weight': 300.0,
        'imageUrls': <String>[],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      final legacy = Product.fromFirestore(
          await fakeFirestore.collection('products').doc('p1').get());

      final result = await provider
          .updateProduct(legacy.copyWith(category: ProductCategory.pottery));

      expect(result, isTrue);
      final doc = await fakeFirestore.collection('products').doc('p1').get();
      expect(doc.data()!['category'], 'pottery');
      expect(doc.data()!['title'], 'Old Mug');
    });
  });
}
