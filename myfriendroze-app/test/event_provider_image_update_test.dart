import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:myfriendroze_admin/models/event.dart';
import 'package:myfriendroze_admin/providers/event_provider.dart';
import 'package:myfriendroze_admin/services/firestore_service.dart';
import 'package:myfriendroze_admin/services/storage_service.dart';

// firebase_storage_mocks' putFile doesn't validate the file exists or fail
// on bad input, so an upload-failure scenario can't be reproduced with it —
// this only covers the happy path. The reorder itself (upload before
// delete, see event_provider.dart) is what actually protects the failure
// case; it isn't exercised here for lack of a way to force that failure.
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
  });
}

String _pathFromUrl(String url) {
  final uri = Uri.parse(url);
  return uri.pathSegments.join('/');
}
