import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:myfriendroze_admin/models/gallery_photo.dart';

void main() {
  group('GalleryPhoto', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('round-trips required fields through Firestore', () async {
      final now = DateTime(2026, 8, 10, 12, 0, 0);
      final photo = GalleryPhoto(
        id: 'placeholder',
        imageUrl: 'https://example.com/photo.jpg',
        altText: 'Blue ceramic planter with succulent',
        caption: null,
        link: null,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await firestore.collection('gallery').add(photo.toFirestore());
      final snapshot = await docRef.get();
      final roundTripped = GalleryPhoto.fromFirestore(snapshot);

      expect(roundTripped.id, docRef.id);
      expect(roundTripped.imageUrl, photo.imageUrl);
      expect(roundTripped.altText, photo.altText);
      expect(roundTripped.caption, isNull);
      expect(roundTripped.link, isNull);
      expect(roundTripped.createdAt, now);
      expect(roundTripped.updatedAt, now);
      expect(roundTripped.isActive, isTrue);
    });

    test('round-trips optional caption and link when provided', () async {
      final now = DateTime(2026, 8, 10, 12, 0, 0);
      final photo = GalleryPhoto(
        id: 'placeholder',
        imageUrl: 'https://example.com/photo.jpg',
        altText: 'Yellow lined planter',
        caption: 'Fresh off the wheel',
        link: 'https://instagram.com/p/abc123',
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await firestore.collection('gallery').add(photo.toFirestore());
      final snapshot = await docRef.get();
      final roundTripped = GalleryPhoto.fromFirestore(snapshot);

      expect(roundTripped.caption, 'Fresh off the wheel');
      expect(roundTripped.link, 'https://instagram.com/p/abc123');
    });

    test('defaults isActive to true when field is missing', () async {
      // Simulates a legacy/partial doc written without isActive set.
      final now = DateTime(2026, 8, 10, 12, 0, 0);
      final docRef = await firestore.collection('gallery').add({
        'imageUrl': 'https://example.com/photo.jpg',
        'altText': 'Pineapple planter',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      final snapshot = await docRef.get();
      final photo = GalleryPhoto.fromFirestore(snapshot);

      expect(photo.isActive, isTrue);
    });

    test('isActive false round-trips as false, not the default', () async {
      final now = DateTime(2026, 8, 10, 12, 0, 0);
      final photo = GalleryPhoto(
        id: 'placeholder',
        imageUrl: 'https://example.com/photo.jpg',
        altText: 'Retired photo',
        createdAt: now,
        updatedAt: now,
        isActive: false,
      );

      final docRef = await firestore.collection('gallery').add(photo.toFirestore());
      final snapshot = await docRef.get();
      final roundTripped = GalleryPhoto.fromFirestore(snapshot);

      expect(roundTripped.isActive, isFalse);
    });

    test('copyWith overrides only the given fields', () {
      final now = DateTime(2026, 8, 10, 12, 0, 0);
      final photo = GalleryPhoto(
        id: 'abc',
        imageUrl: 'https://example.com/photo.jpg',
        altText: 'Original alt text',
        caption: 'Original caption',
        createdAt: now,
        updatedAt: now,
      );

      final updated = photo.copyWith(altText: 'Updated alt text');

      expect(updated.altText, 'Updated alt text');
      expect(updated.caption, 'Original caption');
      expect(updated.imageUrl, photo.imageUrl);
      expect(updated.id, photo.id);
    });
  });
}
