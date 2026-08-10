import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:myfriendroze_admin/models/gallery_photo.dart';
import 'package:myfriendroze_admin/services/firestore_service.dart';

void main() {
  group('FirestoreService gallery operations', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      FirestoreService.setFirestoreInstance(fakeFirestore);
    });

    GalleryPhoto buildPhoto({String id = 'placeholder', bool isActive = true, String altText = 'Alt text'}) {
      final now = DateTime(2026, 8, 10, 12, 0, 0);
      return GalleryPhoto(
        id: id,
        imageUrl: 'https://example.com/photo.jpg',
        altText: altText,
        createdAt: now,
        updatedAt: now,
        isActive: isActive,
      );
    }

    test('addGalleryPhoto persists the photo and returns a generated id', () async {
      final id = await FirestoreService.addGalleryPhoto(buildPhoto());

      expect(id, isNotEmpty);
      final doc = await fakeFirestore.collection('gallery').doc(id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['altText'], 'Alt text');
    });

    test('getGalleryPhotos stream emits photos ordered by createdAt descending', () async {
      final older = GalleryPhoto(
        id: 'placeholder',
        imageUrl: 'https://example.com/older.jpg',
        altText: 'Older photo',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final newer = GalleryPhoto(
        id: 'placeholder',
        imageUrl: 'https://example.com/newer.jpg',
        altText: 'Newer photo',
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );
      await FirestoreService.addGalleryPhoto(older);
      await FirestoreService.addGalleryPhoto(newer);

      final photos = await FirestoreService.getGalleryPhotos().first;

      expect(photos.length, 2);
      expect(photos.first.altText, 'Newer photo');
      expect(photos.last.altText, 'Older photo');
    });

    test('updateGalleryPhoto overwrites fields on the existing doc', () async {
      final id = await FirestoreService.addGalleryPhoto(buildPhoto());
      final updated = buildPhoto(id: id, altText: 'Updated alt text');

      await FirestoreService.updateGalleryPhoto(updated);

      final doc = await fakeFirestore.collection('gallery').doc(id).get();
      expect(doc.data()!['altText'], 'Updated alt text');
    });

    test('deleteGalleryPhoto removes the doc', () async {
      final id = await FirestoreService.addGalleryPhoto(buildPhoto());

      await FirestoreService.deleteGalleryPhoto(id);

      final doc = await fakeFirestore.collection('gallery').doc(id).get();
      expect(doc.exists, isFalse);
    });

    test('getGalleryPhoto returns null for a missing doc', () async {
      final photo = await FirestoreService.getGalleryPhoto('does-not-exist');

      expect(photo, isNull);
    });

    test('getGalleryPhoto returns the matching photo when it exists', () async {
      final id = await FirestoreService.addGalleryPhoto(buildPhoto(altText: 'Findable'));

      final photo = await FirestoreService.getGalleryPhoto(id);

      expect(photo, isNotNull);
      expect(photo!.altText, 'Findable');
    });
  });
}
