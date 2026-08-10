import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:myfriendroze_admin/providers/gallery_provider.dart';
import 'package:myfriendroze_admin/services/firestore_service.dart';
import 'package:myfriendroze_admin/services/storage_service.dart';

void main() {
  group('GalleryProvider', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseStorage mockStorage;
    late GalleryProvider provider;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockStorage = MockFirebaseStorage();
      FirestoreService.setFirestoreInstance(fakeFirestore);
      StorageService.setStorageInstance(mockStorage);
      provider = GalleryProvider();
    });

    test('addGalleryPhoto uploads the image, persists metadata, and returns true', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      final result = await provider.addGalleryPhoto(
        altText: 'Blue ceramic planter',
        caption: 'Fresh off the wheel',
        imageBytesList: [bytes],
      );

      expect(result, isTrue);
      expect(provider.errorMessage, isNull);
      final docs = await fakeFirestore.collection('gallery').get();
      expect(docs.docs.length, 1);
      expect(docs.docs.first.data()['altText'], 'Blue ceramic planter');
      expect(docs.docs.first.data()['imageUrl'], isNotEmpty);
    });

    test('addGalleryPhoto fails fast with an error when no image is provided', () async {
      final result = await provider.addGalleryPhoto(altText: 'No image here');

      expect(result, isFalse);
      expect(provider.errorMessage, isNotNull);
      final docs = await fakeFirestore.collection('gallery').get();
      expect(docs.docs, isEmpty);
    });

    test('loadGalleryPhotos populates photos from the Firestore stream', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      await provider.addGalleryPhoto(altText: 'First photo', imageBytesList: [bytes]);

      provider.loadGalleryPhotos();
      await Future<void>.delayed(Duration.zero);

      expect(provider.photos.length, 1);
      expect(provider.photos.first.altText, 'First photo');
    });

    test('deleteGalleryPhoto removes both the storage image and the Firestore doc', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      await provider.addGalleryPhoto(altText: 'To be deleted', imageBytesList: [bytes]);
      final docs = await fakeFirestore.collection('gallery').get();
      final photo = await FirestoreService.getGalleryPhoto(docs.docs.first.id);

      final result = await provider.deleteGalleryPhoto(photo!);

      expect(result, isTrue);
      final remaining = await fakeFirestore.collection('gallery').get();
      expect(remaining.docs, isEmpty);
    });

    test('updateGalleryPhoto replaces the image when new bytes are provided', () async {
      final originalBytes = Uint8List.fromList([1, 2, 3, 4]);
      await provider.addGalleryPhoto(altText: 'Original', imageBytesList: [originalBytes]);
      final docs = await fakeFirestore.collection('gallery').get();
      final photo = await FirestoreService.getGalleryPhoto(docs.docs.first.id);
      final originalUrl = photo!.imageUrl;

      final newBytes = Uint8List.fromList([5, 6, 7, 8]);
      final result = await provider.updateGalleryPhoto(
        photo,
        altText: 'Updated',
        newImageBytesList: [newBytes],
      );

      expect(result, isTrue);
      final updatedDoc = await fakeFirestore.collection('gallery').doc(photo.id).get();
      expect(updatedDoc.data()!['altText'], 'Updated');
      expect(updatedDoc.data()!['imageUrl'], isNot(equals(originalUrl)));
    });
  });
}
