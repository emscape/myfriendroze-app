import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'api_client.dart';

/// Sync status for products with Astro site
enum SyncStatus {
  pending,
  synced,
  failed,
  notSynced;

  String get displayName {
    switch (this) {
      case SyncStatus.pending:
        return 'Syncing...';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.failed:
        return 'Sync Failed';
      case SyncStatus.notSynced:
        return 'Not Synced';
    }
  }
}

/// Product sync result
class ProductSyncResult {
  final bool success;
  final String? error;
  final DateTime timestamp;
  final String? astroProductId;

  const ProductSyncResult({
    required this.success,
    this.error,
    required this.timestamp,
    this.astroProductId,
  });

  factory ProductSyncResult.success({String? astroProductId}) {
    return ProductSyncResult(
      success: true,
      timestamp: DateTime.now(),
      astroProductId: astroProductId,
    );
  }

  factory ProductSyncResult.failure(String error) {
    return ProductSyncResult(
      success: false,
      error: error,
      timestamp: DateTime.now(),
    );
  }
}

/// Service for syncing products with Astro site
class AstroIntegrationService {
  final ApiClient _apiClient;

  AstroIntegrationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? _createAstroApiClient();

  /// Create a dedicated API client for Astro webhook
  static ApiClient _createAstroApiClient() {
    return ApiClient.withConfig(ApiConfig.astroWebhook);
  }

  /// Convert Flutter Product to Astro-compatible format
  Map<String, dynamic> _convertProductToAstroFormat(Product product) {
    // Generate handle from title (URL-friendly slug)
    final handle = _generateHandle(product.title);

    return {
      'id': product.id,
      'handle': handle,
      'title': product.title,
      'description': product.description,
      'price': product.price,
      'compareAtPrice': null, // Could be added to Product model later
      'images': product.imageUrls,
      'tags': _generateTags(product), // Generate tags from product data
      'inStock': product.isActive,
      'weight': product.weight,
      'createdAt': product.createdAt.toIso8601String(),
      'updatedAt': product.updatedAt.toIso8601String(),
    };
  }

  /// Generate URL-friendly handle from product title
  String _generateHandle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), '-') // Replace spaces with hyphens
        .replaceAll(RegExp(r'-+'), '-') // Replace multiple hyphens with single
        .replaceAll(RegExp(r'^-|-$'), ''); // Remove leading/trailing hyphens
  }

  /// Generate tags from product data
  List<String> _generateTags(Product product) {
    final tags = <String>[];

    // Add price-based tags
    if (product.price < 20) {
      tags.add('affordable');
    } else if (product.price > 100) {
      tags.add('premium');
    }

    // Add weight-based tags
    if (product.weight < 0.5) {
      tags.add('lightweight');
    } else if (product.weight > 2.0) {
      tags.add('heavy');
    }

    // Add availability tag
    if (product.isActive) {
      tags.add('available');
    }

    return tags;
  }

  /// Sync a single product to Astro site
  Future<ProductSyncResult> syncProduct(Product product) async {
    try {
      if (kDebugMode) {
        print('Syncing product to Astro: ${product.title} (${product.id})');
      }

      final astroProduct = _convertProductToAstroFormat(product);

      // For now, we'll use a webhook approach
      // In the future, this could be swapped for direct Firestore writes
      // or other integration methods
      final response = await _apiClient.post(
        '/products/sync',
        body: {
          'action': 'upsert',
          'product': astroProduct,
        },
      );

      if (kDebugMode) {
        print('Product sync response: $response');
      }

      return ProductSyncResult.success(
        astroProductId: response['id'] as String?,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Product sync failed: $e');
      }

      return ProductSyncResult.failure(e.toString());
    }
  }

  /// Sync multiple products to Astro site
  Future<List<ProductSyncResult>> syncProducts(List<Product> products) async {
    final results = <ProductSyncResult>[];

    for (final product in products) {
      final result = await syncProduct(product);
      results.add(result);

      // Add small delay to avoid overwhelming the API
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return results;
  }

  /// Remove a product from Astro site
  Future<ProductSyncResult> removeProduct(String productId) async {
    try {
      if (kDebugMode) {
        print('Removing product from Astro: $productId');
      }

      await _apiClient.post(
        '/products/sync',
        body: {
          'action': 'delete',
          'productId': productId,
        },
      );

      return ProductSyncResult.success();
    } catch (e) {
      if (kDebugMode) {
        print('Product removal failed: $e');
      }

      return ProductSyncResult.failure(e.toString());
    }
  }

  /// Trigger a full rebuild of the Astro site
  Future<bool> triggerSiteRebuild() async {
    try {
      if (kDebugMode) {
        print('Triggering Astro site rebuild');
      }

      await _apiClient.post('/rebuild');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Site rebuild failed: $e');
      }

      return false;
    }
  }

  /// Check if Astro integration is available
  Future<bool> checkIntegrationHealth() async {
    try {
      final response = await _apiClient.get('/health');
      return response['status'] == 'ok';
    } catch (e) {
      if (kDebugMode) {
        print('Astro integration health check failed: $e');
      }

      return false;
    }
  }

  /// Get sync statistics
  Future<Map<String, dynamic>?> getSyncStats() async {
    try {
      return await _apiClient.get('/products/stats');
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get sync stats: $e');
      }

      return null;
    }
  }
}

/// Singleton instance for easy access
class AstroIntegrationManager {
  static AstroIntegrationService? _instance;

  static AstroIntegrationService get instance {
    _instance ??= AstroIntegrationService();
    return _instance!;
  }

  static void dispose() {
    _instance = null;
  }
}
