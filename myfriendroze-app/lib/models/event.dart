import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  // Nullable, not defaulted to eventDate: a null endDate means "single-day
  // event" and is preserved as null through Firestore, so the Astro site's
  // docToEvent (astro/src/lib/event-mapping.js) can tell "no end date was
  // ever set" apart from "explicitly ends the same day" and fall back to
  // eventDate itself rather than trusting a value this model invented.
  final DateTime? endDate;
  final String location;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    this.endDate,
    required this.location,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      eventDate: (data['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'eventDate': Timestamp.fromDate(eventDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'location': location,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? eventDate,
    // A plain `DateTime? endDate` param couldn't distinguish "not passed,
    // keep the existing value" from "explicitly clear it back to
    // single-day" — both would look like null. Wrapping the value lets
    // clearEndDate opt into the latter.
    DateTime? endDate,
    bool clearEndDate = false,
    String? location,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
