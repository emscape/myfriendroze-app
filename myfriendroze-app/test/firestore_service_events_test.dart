import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:myfriendroze_admin/models/event.dart';
import 'package:myfriendroze_admin/models/saved_location.dart';
import 'package:myfriendroze_admin/services/firestore_service.dart';

void main() {
  group('FirestoreService event operations', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      FirestoreService.setFirestoreInstance(fakeFirestore);
    });

    Event buildEvent({String id = '', DateTime? endDate}) {
      final now = DateTime(2026, 8, 10, 12, 0, 0);
      return Event(
        id: id,
        title: 'Pasadena Artwalk',
        description: '11a - 6p',
        eventDate: DateTime(2026, 9, 19),
        endDate: endDate,
        location: 'Green St, Pasadena CA',
        createdAt: now,
        updatedAt: now,
      );
    }

    test('addEvent persists an explicit endDate for a multi-day event', () async {
      final id = await FirestoreService.addEvent(buildEvent(endDate: DateTime(2026, 9, 20)));

      final doc = await fakeFirestore.collection('events').doc(id).get();
      expect((doc.data()!['endDate'] as Timestamp).toDate(), DateTime(2026, 9, 20));
    });

    test('updateEvent can change an event from single-day to multi-day', () async {
      final id = await FirestoreService.addEvent(buildEvent());
      final updated = buildEvent(id: id, endDate: DateTime(2026, 9, 20));

      await FirestoreService.updateEvent(updated);

      final doc = await fakeFirestore.collection('events').doc(id).get();
      expect((doc.data()!['endDate'] as Timestamp).toDate(), DateTime(2026, 9, 20));
    });
  });

  group('FirestoreService saved location operations', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      FirestoreService.setFirestoreInstance(fakeFirestore);
    });

    test('addSavedLocation persists the location and returns a generated id', () async {
      final id = await FirestoreService.addSavedLocation(
        SavedLocation(id: '', name: 'Common Space Brewing', address: '3411 El Segundo Blvd, Hawthorne, CA'),
      );

      expect(id, isNotEmpty);
      final doc = await fakeFirestore.collection('savedLocations').doc(id).get();
      expect(doc.data()!['name'], 'Common Space Brewing');
    });

    test('getSavedLocations stream emits saved locations ordered by name', () async {
      await FirestoreService.addSavedLocation(SavedLocation(id: '', name: 'Jackalope Pasadena', address: 'TBD'));
      await FirestoreService.addSavedLocation(SavedLocation(id: '', name: 'Common Space Brewing', address: 'TBD'));

      final locations = await FirestoreService.getSavedLocations().first;

      expect(locations.map((l) => l.name).toList(), ['Common Space Brewing', 'Jackalope Pasadena']);
    });

    test('deleteSavedLocation removes the doc', () async {
      final id = await FirestoreService.addSavedLocation(SavedLocation(id: '', name: 'To delete', address: 'TBD'));

      await FirestoreService.deleteSavedLocation(id);

      final doc = await fakeFirestore.collection('savedLocations').doc(id).get();
      expect(doc.exists, isFalse);
    });
  });
}
