import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryPhoto {
  final String id;
  final String imageUrl;
  final String altText;
  final String? caption;
  final String? link;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  GalleryPhoto({
    required this.id,
    required this.imageUrl,
    required this.altText,
    this.caption,
    this.link,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory GalleryPhoto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GalleryPhoto(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      altText: data['altText'] ?? '',
      caption: data['caption'],
      link: data['link'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'altText': altText,
      'caption': caption,
      'link': link,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  GalleryPhoto copyWith({
    String? id,
    String? imageUrl,
    String? altText,
    String? caption,
    String? link,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return GalleryPhoto(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      altText: altText ?? this.altText,
      caption: caption ?? this.caption,
      link: link ?? this.link,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
