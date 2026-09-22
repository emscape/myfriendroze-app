// Tests for delayed/scheduled product publishing.
//
// A product's publishAt (nullable) lets it stay hidden on the public site
// until a chosen future moment — see astro/src/lib/products-live.js and
// firestore.rules in the myfriendroze (site) repo for the read side. This
// file covers the admin-app-side plumbing: the Product model field and
// ProductProvider.addProduct threading it through.
//
// toFirestore() writes an explicit `null` (not an omitted key) when
// publishAt is unset — the same idiom event.dart already uses for
// link/clearLink — because FirestoreService.updateProduct() uses `.update()`
// (a merge), so an omitted key would silently fail to clear a previously-set
// publishAt when a schedule is cancelled.

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:myfriendroze_admin/models/product.dart';
import 'package:myfriendroze_admin/providers/product_provider.dart';
import 'package:myfriendroze_admin/services/firestore_service.dart';
import 'package:myfriendroze_admin/services/storage_service.dart';

void main() {
  group('Product.publishAt', () {
    test('constructor defaults publishAt to null (publish immediately)', () {
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

      expect(product.publishAt, isNull);
    });

    test('round-trips a future publishAt through Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      final scheduledFor = DateTime(2099, 6, 1, 9, 0);
      final product = Product(
        id: 'p1',
        title: 'Not Yet Revealed',
        description: 'Waiting on its reveal date',
        price: 90,
        weight: 700,
        publishAt: scheduledFor,
        imageUrls: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final docRef = firestore.collection('products').doc('p1');
      await docRef.set(product.toFirestore());
      final snapshot = await docRef.get();
      final roundTripped = Product.fromFirestore(snapshot);

      expect(roundTripped.publishAt, scheduledFor);
    });

    test('fromFirestore defaults missing publishAt to null (existing products predate this feature)', () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('products').doc('legacy');
      await docRef.set({
        'title': 'Old Mug',
        'description': 'No publishAt field on file',
        'price': 15.0,
        'weight': 300.0,
        'imageUrls': <String>[],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      final snapshot = await docRef.get();
      final product = Product.fromFirestore(snapshot);

      expect(product.publishAt, isNull);
    });

    test('copyWith sets publishAt independently of other fields', () {
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
      final scheduledFor = DateTime(2099, 1, 1);

      final scheduled = product.copyWith(publishAt: scheduledFor);

      expect(scheduled.publishAt, scheduledFor);
      expect(scheduled.title, 'Bowl');
    });

    test('copyWith requires clearPublishAt: true to actually clear a previously-set schedule', () {
      final product = Product(
        id: 'p1',
        title: 'Bowl',
        description: 'A bowl',
        price: 20,
        weight: 500,
        publishAt: DateTime(2099, 1, 1),
        imageUrls: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      // Omitting publishAt entirely must leave the existing value alone
      // (same as every other copyWith field) -- only the explicit flag
      // clears it.
      final untouched = product.copyWith(title: 'Renamed Bowl');
      expect(untouched.publishAt, DateTime(2099, 1, 1));

      final cleared = product.copyWith(clearPublishAt: true);
      expect(cleared.publishAt, isNull);
    });

    test('clearing a previously-set publishAt via .update() actually removes it in Firestore, not just locally', () async {
      final firestore = FakeFirebaseFirestore();
      final existing = Product(
        id: 'p1',
        title: 'Scheduled Vase',
        description: 'Was scheduled',
        price: 90,
        weight: 700,
        publishAt: DateTime(2099, 1, 1),
        imageUrls: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final docRef = firestore.collection('products').doc('p1');
      await docRef.set(existing.toFirestore());

      final cleared = existing.copyWith(clearPublishAt: true, updatedAt: DateTime(2026, 2, 1));
      await docRef.update(cleared.toFirestore());

      final snapshot = await docRef.get();
      expect(snapshot.data()!['publishAt'], isNull);
      expect(Product.fromFirestore(snapshot).publishAt, isNull);
    });
  });

  group('ProductProvider.addProduct with publishAt', () {
    late FakeFirebaseFirestore fakeFirestore;
    late ProductProvider provider;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      FirestoreService.setFirestoreInstance(fakeFirestore);
      StorageService.setStorageInstance(MockFirebaseStorage());
      provider = ProductProvider();
    });

    test('passes publishAt through to the created Firestore doc', () async {
      final scheduledFor = DateTime(2099, 3, 1, 12, 0);

      final result = await provider.addProduct(
        title: 'Future Drop',
        description: 'Revealed later',
        price: 45,
        weight: 400,
        publishAt: scheduledFor,
      );

      expect(result, isTrue);
      final snapshot = await fakeFirestore.collection('products').get();
      expect(snapshot.docs, hasLength(1));
      final saved = Product.fromFirestore(snapshot.docs.first);
      expect(saved.publishAt, scheduledFor);
    });

    test('defaults to immediate publish (publishAt null) when not provided', () async {
      await provider.addProduct(
        title: 'Live Now',
        description: 'No delay',
        price: 20,
        weight: 200,
      );

      final snapshot = await fakeFirestore.collection('products').get();
      final saved = Product.fromFirestore(snapshot.docs.first);
      expect(saved.publishAt, isNull);
    });
  });
}
