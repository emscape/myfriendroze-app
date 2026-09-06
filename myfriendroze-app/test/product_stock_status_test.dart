// Tests for the "mark as sold out" feature.
//
// The Astro site (product-mapping.js's docToProduct) and the checkout
// boundary (firebase/functions/lib/pricing.js) already read/enforce an
// `inStock` field on the product Firestore doc — that plumbing was built
// and tested but had no way to actually be set, since the Flutter admin
// app's Product model never had an inStock field at all. This closes that
// gap using the exact field name the site/checkout already expect, so no
// further site-side change is needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:myfriendroze_admin/models/product.dart';
import 'package:myfriendroze_admin/providers/product_provider.dart';
import 'package:myfriendroze_admin/services/firestore_service.dart';
import 'package:myfriendroze_admin/services/storage_service.dart';

void main() {
  group('Product.inStock', () {
    test('constructor defaults inStock to true when omitted', () {
      final product = Product(
        id: 'p1',
        title: 'Bowl',
        description: 'A bowl',
        price: 20,
        weight: 500,
        imageUrls: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(product.inStock, isTrue);
    });

    test('round-trips inStock: false through Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      final product = Product(
        id: 'p1',
        title: 'One-of-a-kind Vase',
        description: 'Sold at the last show',
        price: 90,
        weight: 700,
        inStock: false,
        imageUrls: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final docRef = firestore.collection('products').doc('p1');
      await docRef.set(product.toFirestore());
      final snapshot = await docRef.get();
      final roundTripped = Product.fromFirestore(snapshot);

      expect(roundTripped.inStock, isFalse);
    });

    test('fromFirestore defaults missing inStock to true (existing products predate this feature)', () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('products').doc('legacy');
      await docRef.set({
        'title': 'Old Mug',
        'description': 'No inStock field on file',
        'price': 15.0,
        'weight': 300.0,
        'imageUrls': <String>[],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      final snapshot = await docRef.get();
      final product = Product.fromFirestore(snapshot);

      expect(product.inStock, isTrue);
    });

    test('copyWith flips inStock independently of other fields', () {
      final product = Product(
        id: 'p1',
        title: 'Bowl',
        description: 'A bowl',
        price: 20,
        weight: 500,
        imageUrls: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final soldOut = product.copyWith(inStock: false);

      expect(soldOut.inStock, isFalse);
      expect(soldOut.title, 'Bowl');
    });
  });

  group('ProductProvider.setInStock', () {
    late FakeFirebaseFirestore fakeFirestore;
    late ProductProvider provider;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      FirestoreService.setFirestoreInstance(fakeFirestore);
      StorageService.setStorageInstance(MockFirebaseStorage());
      provider = ProductProvider();
    });

    test('marks a product sold out without touching its other fields', () async {
      final existing = Product(
        id: 'p1',
        title: 'Shino Wins',
        description: 'One-off glaze test',
        price: 100,
        weight: 900,
        imageUrls: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await fakeFirestore.collection('products').doc('p1').set(existing.toFirestore());

      final result = await provider.setInStock(existing, false);

      expect(result, isTrue);
      final doc = await fakeFirestore.collection('products').doc('p1').get();
      expect(doc.data()!['inStock'], isFalse);
      expect(doc.data()!['title'], 'Shino Wins');
    });

    test('marking a product back in stock reverses the flag', () async {
      final existing = Product(
        id: 'p1',
        title: 'Shino Wins',
        description: 'One-off glaze test',
        price: 100,
        weight: 900,
        inStock: false,
        imageUrls: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await fakeFirestore.collection('products').doc('p1').set(existing.toFirestore());

      await provider.setInStock(existing, true);

      final doc = await fakeFirestore.collection('products').doc('p1').get();
      expect(doc.data()!['inStock'], isTrue);
    });
  });
}
