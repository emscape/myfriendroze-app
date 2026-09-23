import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final double weight;
  final double heightIn;
  final double widthIn;
  final double depthIn;
  // The box the item actually ships in — independent of the item's own
  // physical dimensions above, since fragile ceramics typically need a
  // larger, padded box. Used for accurate shipping cost estimates.
  final double shippingBoxHeightIn;
  final double shippingBoxWidthIn;
  final double shippingBoxDepthIn;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  // Distinct from isActive: isActive gates whether a product is fetched/
  // shown on the site at all; inStock marks a still-visible product as
  // sold out (site shows it with a disabled "Sold Out" state instead of
  // hiding it, which matters for one-of-a-kind pieces that stay useful as
  // portfolio/gallery items after they sell). Read by product-mapping.js's
  // docToProduct and enforced server-side at the checkout boundary in
  // firebase/functions/lib/pricing.js — this is the admin-side control for
  // both.
  final bool inStock;
  // Delayed/scheduled publish: when set to a future moment, the product
  // stays hidden from the public site until then (site-side gating lives in
  // astro/src/lib/products-live.js and firestore.rules in the site repo).
  // Null means "publish immediately" -- the pre-existing default behavior,
  // so every product created before this feature keeps working unchanged.
  final DateTime? publishAt;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.weight,
    this.heightIn = 0.0,
    this.widthIn = 0.0,
    this.depthIn = 0.0,
    this.shippingBoxHeightIn = 0.0,
    this.shippingBoxWidthIn = 0.0,
    this.shippingBoxDepthIn = 0.0,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.inStock = true,
    this.publishAt,
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
      shippingBoxHeightIn: (data['shippingBoxHeightIn'] ?? 0.0).toDouble(),
      shippingBoxWidthIn: (data['shippingBoxWidthIn'] ?? 0.0).toDouble(),
      shippingBoxDepthIn: (data['shippingBoxDepthIn'] ?? 0.0).toDouble(),
      imageUrls: imageUrls,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      // Existing products predate this feature — default to purchasable,
      // matching product-mapping.js's docToProduct on the site side.
      inStock: data['inStock'] ?? true,
      publishAt: (data['publishAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'weight': weight,
      'heightIn': heightIn,
      'widthIn': widthIn,
      'depthIn': depthIn,
      'shippingBoxHeightIn': shippingBoxHeightIn,
      'shippingBoxWidthIn': shippingBoxWidthIn,
      'shippingBoxDepthIn': shippingBoxDepthIn,
      'imageUrls': imageUrls,
      // Keep imageUrl for backwards compatibility
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'inStock': inStock,
      // Explicit null (not an omitted key) when unset -- FirestoreService
      // writes products via .update() (a merge), so an omitted key would
      // silently fail to clear a previously-set publishAt when a schedule
      // is cancelled. Same idiom as event.dart's link/clearLink.
      'publishAt': publishAt != null ? Timestamp.fromDate(publishAt!) : null,
    };
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
    double? shippingBoxHeightIn,
    double? shippingBoxWidthIn,
    double? shippingBoxDepthIn,
    List<String>? imageUrls,
    String? imageUrl, // backwards compatibility
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? inStock,
    DateTime? publishAt,
    // clearPublishAt opts into actually removing a previously-set schedule.
    bool clearPublishAt = false,
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
      shippingBoxHeightIn: shippingBoxHeightIn ?? this.shippingBoxHeightIn,
      shippingBoxWidthIn: shippingBoxWidthIn ?? this.shippingBoxWidthIn,
      shippingBoxDepthIn: shippingBoxDepthIn ?? this.shippingBoxDepthIn,
      imageUrls: finalImageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      inStock: inStock ?? this.inStock,
      publishAt: clearPublishAt ? null : (publishAt ?? this.publishAt),
    );
  }
}
