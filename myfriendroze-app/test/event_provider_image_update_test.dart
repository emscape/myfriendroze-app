import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:myfriendroze_admin/models/event.dart';
import 'package:myfriendroze_admin/providers/event_provider.dart';
import 'package:myfriendroze_admin/services/firestore_service.dart';
import 'package:myfriendroze_admin/services/storage_service.dart';

// firebase_storage_mocks' putFile doesn't validate the file exists or fail
// on bad input, so an upload-failure scenario can't be reproduced with it.
// Firestore-write failure IS reproducible (.update() on a missing doc
// throws), which covers the second half of event_provider.dart's
// upload-then-write-then-cleanup ordering — but see the note in that test
// for what still isn't independently verified even there.
//
// Not covered at all here: the "write actually committed server-side but
// the client saw an exception anyway" scenario updateEvent's reconciliation
// read (getEvent) specifically guards against. Forcing FakeFirebaseFirestore
// to both apply an .update() AND throw from it would need a seam this
// codebase doesn't have; verified by code review instead.
//
// Also worth noting: this whole suite runs in the Dart VM, where dart:io's
// File works normally — so the File-based tests below could never have
// caught the real production bug (putFile()/Image.file() both throw
// UnimplementedError on an actual web build, where dart:io isn't
// implemented at all). The bytes-based group exists specifically because
// that's the path a real web/PWA session actually takes.
void main() {
  group('EventProvider.updateEvent image replacement', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseStorage mockStorage;
    late EventProvider provider;
    late File tempImageFile;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      mockStorage = MockFirebaseStorage();
      FirestoreService.setFirestoreInstance(fakeFirestore);
      StorageService.setStorageInstance(mockStorage);
      provider = EventProvider();

      tempImageFile = File(
        '${Directory.systemTemp.path}/event_provider_image_update_test_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await tempImageFile.writeAsBytes([1, 2, 3, 4]);
    });

    tearDown(() async {
      if (await tempImageFile.exists()) {
        await tempImageFile.delete();
      }
    });

    test('replaces the image, and the old one is gone once the new one is live', () async {
      await provider.addEvent(
        title: 'Mezcala',
        description: '9a - 2p',
        eventDate: DateTime(2026, 8, 22),
        location: '6901 Orange Ave, Long Beach, CA',
        imageFile: tempImageFile,
      );
      final addedDocs = await fakeFirestore.collection('events').get();
      final original = Event.fromFirestore(addedDocs.docs.first);
      final oldImageUrl = original.imageUrl!;

      final result = await provider.updateEvent(original, newImageFile: tempImageFile);

      expect(result, isTrue);
      final doc = await fakeFirestore.collection('events').doc(original.id).get();
      final newImageUrl = doc.data()!['imageUrl'] as String;
      expect(newImageUrl, isNot(equals(oldImageUrl)));

      // The old image was cleaned up once the new one was safely live —
      // its reference no longer resolves. getDownloadURL() can throw
      // synchronously here (before returning a Future at all), so the
      // closure form is used rather than awaiting the call directly.
      expect(
        () => mockStorage.ref().child(_pathFromUrl(oldImageUrl)).getDownloadURL(),
        throwsA(anything),
      );
    });

    test('reports failure and leaves the original doc untouched when the Firestore write fails on a missing doc', () async {
      await provider.addEvent(
        title: 'Mezcala',
        description: '9a - 2p',
        eventDate: DateTime(2026, 8, 22),
        location: '6901 Orange Ave, Long Beach, CA',
        imageFile: tempImageFile,
      );
      final addedDocs = await fakeFirestore.collection('events').get();
      final original = Event.fromFirestore(addedDocs.docs.first);
      final oldImageUrl = original.imageUrl!;

      // .update() on a doc that doesn't exist throws NOT_FOUND on real
      // Firestore (and on the fake) — used here to force the write to fail
      // without needing to fake a network error. Since the doc can't be
      // found at all, updateEvent's reconciliation read (getEvent) also
      // returns null here, so it conservatively does NOT attempt to
      // delete the replacement upload in this particular scenario — see
      // event_provider.dart's comment on why "can't confirm" defaults to
      // leaving the Storage object alone rather than risking a live image.
      final eventWithMissingDoc = original.copyWith(id: 'does-not-exist-in-firestore');

      final result = await provider.updateEvent(eventWithMissingDoc, newImageFile: tempImageFile);

      expect(result, isFalse);
      expect(provider.errorMessage, isNotNull);

      // The original doc's imageUrl is untouched — the write never
      // succeeded, so it's still the real event's live photo.
      final untouchedDocs = await fakeFirestore.collection('events').get();
      expect(untouchedDocs.docs.first.data()['imageUrl'], oldImageUrl);

      // NOTE: this does NOT independently verify the orphaned replacement
      // upload was actually deleted from Storage — a mockStorage.listAll()
      // item-count check was tried and passed identically whether the
      // cleanup code was present or removed (confirmed by temporarily
      // reverting the fix), so it wasn't discriminating between correct
      // and broken behavior and was dropped rather than kept as a test
      // that looks meaningful but isn't. That half of the fix is verified
      // by code review only.
    });
  });

  group('EventProvider image upload (bytes path — web)', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseStorage mockStorage;
    late EventProvider provider;
    final imageBytes = Uint8List.fromList([1, 2, 3, 4]);

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockStorage = MockFirebaseStorage();
      FirestoreService.setFirestoreInstance(fakeFirestore);
      StorageService.setStorageInstance(mockStorage);
      provider = EventProvider();
    });

    test('addEvent uploads via bytes instead of putFile when imageBytes is given', () async {
      final result = await provider.addEvent(
        title: 'Mezcala',
        description: '9a - 2p',
        eventDate: DateTime(2026, 8, 22),
        location: '6901 Orange Ave, Long Beach, CA',
        imageBytes: imageBytes,
      );

      expect(result, isTrue);
      final docs = await fakeFirestore.collection('events').get();
      expect(docs.docs.first.data()['imageUrl'], isNotEmpty);
    });

    test('updateEvent uploads a replacement via bytes and cleans up the old image', () async {
      await provider.addEvent(
        title: 'Mezcala',
        description: '9a - 2p',
        eventDate: DateTime(2026, 8, 22),
        location: '6901 Orange Ave, Long Beach, CA',
        imageBytes: imageBytes,
      );
      final addedDocs = await fakeFirestore.collection('events').get();
      final original = Event.fromFirestore(addedDocs.docs.first);
      final oldImageUrl = original.imageUrl!;

      final result = await provider.updateEvent(
        original,
        newImageBytes: Uint8List.fromList([5, 6, 7, 8]),
      );

      expect(result, isTrue);
      final doc = await fakeFirestore.collection('events').doc(original.id).get();
      final newImageUrl = doc.data()!['imageUrl'] as String;
      expect(newImageUrl, isNot(equals(oldImageUrl)));
      expect(
        () => mockStorage.ref().child(_pathFromUrl(oldImageUrl)).getDownloadURL(),
        throwsA(anything),
      );
    });
  });
}

String _pathFromUrl(String url) {
  final uri = Uri.parse(url);
  return uri.pathSegments.join('/');
}
