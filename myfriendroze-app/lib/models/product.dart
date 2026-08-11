import 'package:cloud_firestore/cloud_firestore.dart';

/// Sync status for products with external systems (like Astro site)
enum ProductSyncStatus {
  pending,
  synced,
  failed,
  notSynced;

  String get displayName {
    switch (this) {
      case ProductSyncStatus.pending:
        return 'Syncing...';
      case ProductSyncStatus.synced:
        return 'Synced';
      case ProductSyncStatus.failed:
        return 'Sync Failed';
      case ProductSyncStatus.notSynced:
        return 'Not Synced';
    }
  }

  static ProductSyncStatus fromString(String? status) {
    if (status == null) return ProductSyncStatus.notSynced;
    return ProductSyncStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => ProductSyncStatus.notSynced,
    );
  }
}

class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final double weight;
  final double heightIn;
  final double widthIn;
  final double depthIn;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final ProductSyncStatus syncStatus;
  final DateTime? lastSyncAt;
  final String? syncError;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.weight,
    this.heightIn = 0.0,
    this.widthIn = 0.0,
    this.depthIn = 0.0,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.syncStatus = ProductSyncStatus.notSynced,
    this.lastSyncAt,
    this.syncError,
  });

  // Backwards compatibility getter
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  // Convenience getter for primary image
  String get primaryImageUrl => imageUrl;

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle backwards compatibility: migrate single imageUrl to imageUrls list
    List<String> imageUrls = [];
    if (data['imageUrls'] != null) {
      imageUrls = List<String>.from(data['imageUrls']);
    } else if (data['imageUrl'] != null &&
        data['imageUrl'].toString().isNotEmpty) {
      imageUrls = [data['imageUrl']];
    }

    return Product(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      weight: (data['weight'] ?? 0.0).toDouble(),
      // Existing products predate this feature and won't have these fields.
      heightIn: (data['heightIn'] ?? 0.0).toDouble(),
      widthIn: (data['widthIn'] ?? 0.0).toDouble(),
      depthIn: (data['depthIn'] ?? 0.0).toDouble(),
      imageUrls: imageUrls,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      syncStatus: ProductSyncStatus.fromString(data['syncStatus'] as String?),
      lastSyncAt: (data['lastSyncAt'] as Timestamp?)?.toDate(),
      syncError: data['syncError'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = {
      'title': title,
      'description': description,
      'price': price,
      'weight': weight,
      'heightIn': heightIn,
      'widthIn': widthIn,
      'depthIn': depthIn,
      'imageUrls': imageUrls,
      // Keep imageUrl for backwards compatibility
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'syncStatus': syncStatus.name,
    };

    if (lastSyncAt != null) {
      data['lastSyncAt'] = Timestamp.fromDate(lastSyncAt!);
    }

    if (syncError != null) {
      data['syncError'] = syncError!;
    }

    return data;
  }

  Product copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    double? weight,
    double? heightIn,
    double? widthIn,
    double? depthIn,
    List<String>? imageUrls,
    String? imageUrl, // backwards compatibility
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    ProductSyncStatus? syncStatus,
    DateTime? lastSyncAt,
    String? syncError,
  }) {
    List<String> finalImageUrls = imageUrls ?? this.imageUrls;

    // Handle backwards compatibility: if imageUrl is provided, use it as single image
    if (imageUrl != null && imageUrls == null) {
      finalImageUrls = imageUrl.isEmpty ? [] : [imageUrl];
    }

    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      weight: weight ?? this.weight,
      heightIn: heightIn ?? this.heightIn,
      widthIn: widthIn ?? this.widthIn,
      depthIn: depthIn ?? this.depthIn,
      imageUrls: finalImageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncError: syncError ?? this.syncError,
    );
  }
}
