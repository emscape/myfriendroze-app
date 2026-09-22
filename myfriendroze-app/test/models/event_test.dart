import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myfriendroze_admin/models/event.dart';

void main() {
  group('Event.fromFirestore / toFirestore round-trip', () {
    test('preserves an explicit endDate for a multi-day event', () async {
      final firestore = FakeFirebaseFirestore();
      final original = Event(
        id: '',
        title: 'Pasadena Artwalk',
        description: '11a - 6p',
        eventDate: DateTime(2026, 9, 19),
        endDate: DateTime(2026, 9, 20),
        location: 'Green St, Pasadena CA',
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

      final ref = await firestore.collection('events').add(original.toFirestore());
      final snapshot = await ref.get();
      final roundTripped = Event.fromFirestore(snapshot);

      expect(roundTripped.eventDate, DateTime(2026, 9, 19));
      expect(roundTripped.endDate, DateTime(2026, 9, 20));
    });

    test('leaves endDate null for a single-day event instead of defaulting it to eventDate', () async {
      final firestore = FakeFirebaseFirestore();
      final original = Event(
        id: '',
        title: 'Mezcala',
        description: '9a - 2p',
        eventDate: DateTime(2026, 8, 22),
        location: '6901 Orange Ave, Long Beach, CA',
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

      final ref = await firestore.collection('events').add(original.toFirestore());
      final snapshot = await ref.get();
      final roundTripped = Event.fromFirestore(snapshot);

      expect(roundTripped.endDate, isNull);
    });

    test('fromFirestore defaults a missing endDate field to null (pre-existing docs written before this field existed)', () async {
      // Written by hand (not via Event.toFirestore()) so the doc has no
      // endDate key at all, matching what's actually in Firestore for any
      // event created before this field existed.
      final firestore = FakeFirebaseFirestore();
      final ref = firestore.collection('events').doc('legacy');
      await ref.set({
        'title': 'Legacy event',
        'description': 'no endDate field at all',
        'eventDate': Timestamp.fromDate(DateTime(2026, 8, 22)),
        'location': 'Somewhere',
        'isActive': true,
      });

      final snapshot = await ref.get();
      final event = Event.fromFirestore(snapshot);

      expect(event.endDate, isNull);
    });
  });

  group('Event.copyWith', () {
    final base = Event(
      id: 'abc',
      title: 'Prickly Monster Festival',
      description: '12p - 5p',
      eventDate: DateTime(2026, 9, 6),
      endDate: DateTime(2026, 9, 6),
      location: 'Common Space Brewing',
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );

    test('keeps the existing endDate when neither endDate nor clearEndDate is passed', () {
      final updated = base.copyWith(title: 'Renamed');

      expect(updated.endDate, DateTime(2026, 9, 6));
    });

    test('replaces endDate when a new one is passed', () {
      final updated = base.copyWith(endDate: DateTime(2026, 9, 7));

      expect(updated.endDate, DateTime(2026, 9, 7));
    });

    test('clears endDate back to single-day when clearEndDate is true', () {
      final updated = base.copyWith(clearEndDate: true);

      expect(updated.endDate, isNull);
    });
  });
}
