import 'package:cloud_firestore/cloud_firestore.dart';

// A venue address Roze has entered once and can reuse when adding a future
// event (e.g. Jackalope Pasadena, Common Space Brewing) — entered by her,
// never guessed or hardcoded here, since a wrong real-world address is
// worse than none.
class SavedLocation {
  final String id;
  final String name;
  final String address;

  SavedLocation({
    required this.id,
    required this.name,
    required this.address,
  });

  factory SavedLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedLocation(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
    };
  }
}
