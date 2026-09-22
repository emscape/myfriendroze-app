import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:myfriendroze_admin/providers/saved_location_provider.dart';
import 'package:myfriendroze_admin/services/firestore_service.dart';

void main() {
  group('SavedLocationProvider', () {
    late FakeFirebaseFirestore fakeFirestore;
    late SavedLocationProvider provider;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      FirestoreService.setFirestoreInstance(fakeFirestore);
      provider = SavedLocationProvider();
    });

    test('addLocation persists the location and returns true', () async {
      final result = await provider.addLocation(name: 'Common Space Brewing', address: '3411 El Segundo Blvd, Hawthorne, CA');

      expect(result, isTrue);
      final docs = await fakeFirestore.collection('savedLocations').get();
      expect(docs.docs.length, 1);
      expect(docs.docs.first.data()['name'], 'Common Space Brewing');
    });

    test('loadLocations populates locations from the Firestore stream, sorted by name', () async {
      await provider.addLocation(name: 'Jackalope Pasadena', address: 'TBD');
      await provider.addLocation(name: 'Common Space Brewing', address: 'TBD');

      provider.loadLocations();
      await Future<void>.delayed(Duration.zero);

      expect(provider.locations.map((l) => l.name).toList(), ['Common Space Brewing', 'Jackalope Pasadena']);
    });

    test('loadLocations replaces the previous subscription instead of accumulating listeners', () async {
      // Simulates the add/edit event form being opened multiple times —
      // AddEventScreen.initState calls loadLocations() on this same
      // long-lived provider instance every time.
      provider.loadLocations();
      provider.loadLocations();
      provider.loadLocations();
      await Future<void>.delayed(Duration.zero);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await fakeFirestore.collection('savedLocations').add({'name': 'New Venue', 'address': 'TBD'});
      await Future<void>.delayed(Duration.zero);

      // One Firestore change should notify exactly once — three
      // accumulated subscriptions would notify three times instead.
      expect(notifyCount, 1);
    });

    test('deleteLocation removes the Firestore doc', () async {
      await provider.addLocation(name: 'To delete', address: 'TBD');
      final docs = await fakeFirestore.collection('savedLocations').get();
      final location = docs.docs.first;
      provider.loadLocations();
      await Future<void>.delayed(Duration.zero);

      final result = await provider.deleteLocation(provider.locations.firstWhere((l) => l.id == location.id));

      expect(result, isTrue);
      final remaining = await fakeFirestore.collection('savedLocations').get();
      expect(remaining.docs, isEmpty);
    });
  });
}
