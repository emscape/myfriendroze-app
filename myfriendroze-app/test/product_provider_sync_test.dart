// Regression test for the "Sync Failed" bug reported on real phones.
//
// Root cause: ApiConfig.astroWebhook (lib/services/api_client.dart) is
// hardcoded to http://localhost:4321/api — on a real device, "localhost"
// means the phone itself, so this call can never succeed. Worse, the
// Astro-side sync.js route it targets only mutates an in-memory array
// that's discarded on every rebuild (see astro/src/pages/api/products/
// sync.js's own comment) — it never provided real persistence. Actual
// product data flows through Firestore -> the Astro build's prebuild
// script, which this legacy webhook has no bearing on at all.
//
// Fix: addProduct/updateProduct no longer attempt this doomed sync call.
// This test asserts on the real observable symptom (a product's
// syncStatus never gets set to failed/pending by a normal save) rather
// than mocking AstroIntegrationService directly, since removing the call
// entirely is the actual fix, not making the call succeed.

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:myfriendroze_admin/providers/product_provider.dart';
import 'package:myfriendroze_admin/models/product.dart';
import 'package:myfriendroze_admin/services/firestore_service.dart';
import 'package:myfriendroze_admin/services/storage_service.dart';

void main() {
  group('ProductProvider does not attempt the dead Astro sync webhook', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseStorage mockStorage;
    late ProductProvider provider;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockStorage = MockFirebaseStorage();
      FirestoreService.setFirestoreInstance(fakeFirestore);
      StorageService.setStorageInstance(mockStorage);
      provider = ProductProvider();
    });

    test('addProduct leaves syncStatus at its default, never pending/failed', () async {
      final result = await provider.addProduct(
        title: 'Blue Branches',
        description: 'A tall planter',
        price: 70,
        weight: 900,
      );

      expect(result, isTrue);
      expect(provider.errorMessage, isNull);

      final docs = await fakeFirestore.collection('products').get();
      expect(docs.docs.length, 1);
      expect(docs.docs.first.data()['syncStatus'], 'notSynced');
    });

    test('updateProduct leaves syncStatus untouched by a normal edit', () async {
      final existing = Product(
        id: 'p1',
        title: 'Blue Branches',
        description: 'A tall planter',
        price: 70,
        weight: 900,
        imageUrls: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await fakeFirestore.collection('products').doc('p1').set(existing.toFirestore());

      final result = await provider.updateProduct(
        existing.copyWith(price: 75),
      );

      expect(result, isTrue);
      expect(provider.errorMessage, isNull);

      final doc = await fakeFirestore.collection('products').doc('p1').get();
      expect(doc.data()!['price'], 75);
      expect(doc.data()!['syncStatus'], 'notSynced');
    });
  });
}
