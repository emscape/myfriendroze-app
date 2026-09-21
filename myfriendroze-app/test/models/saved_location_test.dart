import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myfriendroze_admin/models/saved_location.dart';

void main() {
  group('SavedLocation.fromFirestore / toFirestore round-trip', () {
    test('preserves name and address', () async {
      final firestore = FakeFirebaseFirestore();
      final original = SavedLocation(id: '', name: 'Common Space Brewing', address: '3411 El Segundo Blvd, Hawthorne, CA');

      final ref = await firestore.collection('savedLocations').add(original.toFirestore());
      final snapshot = await ref.get();
      final roundTripped = SavedLocation.fromFirestore(snapshot);

      expect(roundTripped.name, 'Common Space Brewing');
      expect(roundTripped.address, '3411 El Segundo Blvd, Hawthorne, CA');
      expect(roundTripped.id, ref.id);
    });

    test('defaults missing name/address to empty strings rather than throwing', () async {
      final firestore = FakeFirebaseFirestore();
      final ref = firestore.collection('savedLocations').doc('bare');
      await ref.set(<String, dynamic>{});

      final snapshot = await ref.get();
      final location = SavedLocation.fromFirestore(snapshot);

      expect(location.name, '');
      expect(location.address, '');
    });
  });
}
