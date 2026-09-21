import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:myfriendroze_admin/providers/event_provider.dart';
import 'package:myfriendroze_admin/services/firestore_service.dart';

void main() {
  group('EventProvider', () {
    late FakeFirebaseFirestore fakeFirestore;
    late EventProvider provider;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      FirestoreService.setFirestoreInstance(fakeFirestore);
      provider = EventProvider();
    });

    test('addEvent persists an explicit endDate for a multi-day event', () async {
      final result = await provider.addEvent(
        title: 'Pasadena Artwalk',
        description: '11a - 6p',
        eventDate: DateTime(2026, 9, 19),
        endDate: DateTime(2026, 9, 20),
        location: 'Green St, Pasadena CA',
      );

      expect(result, isTrue);
      final docs = await fakeFirestore.collection('events').get();
      expect(docs.docs.length, 1);
      expect((docs.docs.first.data()['endDate'] as Timestamp).toDate(), DateTime(2026, 9, 20));
    });

    test('addEvent leaves endDate unset for a single-day event', () async {
      await provider.addEvent(
        title: 'Mezcala',
        description: '9a - 2p',
        eventDate: DateTime(2026, 8, 22),
        location: '6901 Orange Ave, Long Beach, CA',
      );

      final docs = await fakeFirestore.collection('events').get();
      expect(docs.docs.first.data()['endDate'], isNull);
    });

    test('loadEvents populates events from the Firestore stream', () async {
      await provider.addEvent(
        title: 'Mezcala',
        description: '9a - 2p',
        eventDate: DateTime(2026, 8, 22),
        location: '6901 Orange Ave, Long Beach, CA',
      );

      provider.loadEvents();
      await Future<void>.delayed(Duration.zero);

      expect(provider.events.length, 1);
      expect(provider.events.first.title, 'Mezcala');
    });
  });
}
