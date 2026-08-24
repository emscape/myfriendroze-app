import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myfriendroze_admin/models/product.dart';

void main() {
  group('Product dimensions (heightIn/widthIn/depthIn)', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('constructor defaults dimensions to zero when omitted', () {
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

      expect(product.heightIn, 0.0);
      expect(product.widthIn, 0.0);
      expect(product.depthIn, 0.0);
    });

    test('round-trips heightIn/widthIn/depthIn through Firestore', () async {
      final product = Product(
        id: 'p1',
        title: 'Vase',
        description: 'A tall vase',
        price: 45,
        weight: 900,
        heightIn: 10.5,
        widthIn: 4.25,
        depthIn: 4.25,
        imageUrls: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final docRef = firestore.collection('products').doc('p1');
      await docRef.set(product.toFirestore());
      final snapshot = await docRef.get();
      final roundTripped = Product.fromFirestore(snapshot);

      expect(roundTripped.heightIn, 10.5);
      expect(roundTripped.widthIn, 4.25);
      expect(roundTripped.depthIn, 4.25);
    });

    test('fromFirestore defaults missing dimension fields to zero '
        '(existing products predate this feature)', () async {
      final docRef = firestore.collection('products').doc('legacy');
      await docRef.set({
        'title': 'Old Mug',
        'description': 'No dimensions on file',
        'price': 15.0,
        'weight': 300.0,
        'imageUrls': <String>[],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      final snapshot = await docRef.get();
      final product = Product.fromFirestore(snapshot);

      expect(product.heightIn, 0.0);
      expect(product.widthIn, 0.0);
      expect(product.depthIn, 0.0);
    });

    test('copyWith updates dimensions independently', () {
      final product = Product(
        id: 'p1',
        title: 'Bowl',
        description: 'A bowl',
        price: 20,
        weight: 500,
        heightIn: 3,
        widthIn: 6,
        depthIn: 6,
        imageUrls: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final updated = product.copyWith(heightIn: 4);

      expect(updated.heightIn, 4);
      expect(updated.widthIn, 6);
      expect(updated.depthIn, 6);
    });
  });

  group('Product shipping box dimensions '
      '(shippingBoxHeightIn/shippingBoxWidthIn/shippingBoxDepthIn)', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('constructor defaults shipping box dimensions to zero when omitted', () {
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

      expect(product.shippingBoxHeightIn, 0.0);
      expect(product.shippingBoxWidthIn, 0.0);
      expect(product.shippingBoxDepthIn, 0.0);
    });

    test('shipping box dimensions are independent of the product\'s own '
        'physical dimensions — a fragile item typically ships in a larger, '
        'padded box', () {
      final product = Product(
        id: 'p1',
        title: 'Vase',
        description: 'A tall vase',
        price: 45,
        weight: 900,
        heightIn: 10.5,
        widthIn: 4.25,
        depthIn: 4.25,
        shippingBoxHeightIn: 14,
        shippingBoxWidthIn: 8,
        shippingBoxDepthIn: 8,
        imageUrls: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(product.heightIn, 10.5);
      expect(product.shippingBoxHeightIn, 14);
      expect(product.shippingBoxWidthIn, 8);
      expect(product.shippingBoxDepthIn, 8);
    });

    test('round-trips shipping box dimensions through Firestore', () async {
      final product = Product(
        id: 'p1',
        title: 'Vase',
        description: 'A tall vase',
        price: 45,
        weight: 900,
        shippingBoxHeightIn: 14,
        shippingBoxWidthIn: 8,
        shippingBoxDepthIn: 8,
        imageUrls: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final docRef = firestore.collection('products').doc('p1');
      await docRef.set(product.toFirestore());
      final snapshot = await docRef.get();
      final roundTripped = Product.fromFirestore(snapshot);

      expect(roundTripped.shippingBoxHeightIn, 14);
      expect(roundTripped.shippingBoxWidthIn, 8);
      expect(roundTripped.shippingBoxDepthIn, 8);
    });

    test('fromFirestore defaults missing shipping box fields to zero '
        '(existing products predate this feature)', () async {
      final docRef = firestore.collection('products').doc('legacy');
      await docRef.set({
        'title': 'Old Mug',
        'description': 'No shipping box dimensions on file',
        'price': 15.0,
        'weight': 300.0,
        'imageUrls': <String>[],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      final snapshot = await docRef.get();
      final product = Product.fromFirestore(snapshot);

      expect(product.shippingBoxHeightIn, 0.0);
      expect(product.shippingBoxWidthIn, 0.0);
      expect(product.shippingBoxDepthIn, 0.0);
    });

    test('copyWith updates shipping box dimensions independently', () {
      final product = Product(
        id: 'p1',
        title: 'Bowl',
        description: 'A bowl',
        price: 20,
        weight: 500,
        shippingBoxHeightIn: 6,
        shippingBoxWidthIn: 9,
        shippingBoxDepthIn: 9,
        imageUrls: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final updated = product.copyWith(shippingBoxHeightIn: 7);

      expect(updated.shippingBoxHeightIn, 7);
      expect(updated.shippingBoxWidthIn, 9);
      expect(updated.shippingBoxDepthIn, 9);
    });
  });
}
