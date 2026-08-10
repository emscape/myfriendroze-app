import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:myfriendroze_admin/models/product.dart';
import 'package:myfriendroze_admin/services/astro_integration_service.dart';
import 'package:myfriendroze_admin/services/api_client.dart';

/// Live integration tests against A1's Astro endpoints
/// These tests require A1's Astro dev server to be running on localhost:4321
void main() {
  group('Live Astro Integration Tests', () {
    late ApiClient apiClient;
    late AstroIntegrationService astroService;

    // Test product data
    final testProduct = Product(
      id: 'test-live-integration-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Live Test Product',
      description: 'This is a test product created by Flutter integration test',
      price: 99.99,
      weight: 2.5,
      imageUrls: [
        'https://example.com/test-image-1.jpg',
        'https://example.com/test-image-2.jpg'
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
    );

    setUpAll(() {
      // Create a custom API client that points directly to A1's Astro server
      // bypassing the MCP bridge for direct testing
      apiClient = ApiClient(environment: ApiEnvironment.dev);
      astroService = AstroIntegrationService(apiClient: apiClient);
    });

    group('Health Check', () {
      test('should connect to A1 Astro health endpoint', () async {
        print('🔍 Testing health check endpoint...');

        final isHealthy = await astroService.checkIntegrationHealth();

        expect(isHealthy, isTrue, reason: 'A1 Astro server should be healthy');
        print('✅ Health check passed!');
      });

      test('should get detailed health information', () async {
        print('🔍 Testing detailed health endpoint...');

        try {
          final response = await http.get(
            Uri.parse('http://localhost:4321/api/health'),
            headers: {'Content-Type': 'application/json'},
          );

          expect(response.statusCode, equals(200));

          final healthData = json.decode(response.body);
          expect(healthData['status'], equals('ok'));

          print('✅ Detailed health check passed!');
          print('📊 Health data: ${json.encode(healthData)}');
        } catch (e) {
          fail('Health check failed: $e');
        }
      });
    });

    group('Single Product Sync', () {
      test('should sync single product to A1 Astro', () async {
        print('🔍 Testing single product sync...');
        print('📦 Product: ${testProduct.title} (ID: ${testProduct.id})');

        final result = await astroService.syncProduct(testProduct);

        expect(result.success, isTrue, reason: 'Product sync should succeed');
        expect(result.error, isNull, reason: 'No error should occur');
        expect(result.astroProductId, isNotNull,
            reason: 'Should return Astro product ID');

        print('✅ Single product sync passed!');
        print('🆔 Astro Product ID: ${result.astroProductId}');
      });
    });

    group('Bulk Product Sync', () {
      test('should sync multiple products to A1 Astro', () async {
        print('🔍 Testing bulk product sync...');

        final bulkProducts = List.generate(
            3,
            (index) => Product(
                  id: 'bulk-test-${DateTime.now().millisecondsSinceEpoch}-$index',
                  title: 'Bulk Test Product ${index + 1}',
                  description:
                      'Bulk test product #${index + 1} for integration testing',
                  price: 10.0 + (index * 5),
                  weight: 1.0 + index,
                  imageUrls: ['https://example.com/bulk-test-$index.jpg'],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  isActive: true,
                ));

        print('📦 Syncing ${bulkProducts.length} products...');

        final results = await astroService.syncProducts(bulkProducts);

        expect(results.length, equals(3),
            reason: 'Should return result for each product');
        expect(results.every((r) => r.success), isTrue,
            reason: 'All syncs should succeed');

        print('✅ Bulk product sync passed!');
        for (int i = 0; i < results.length; i++) {
          print('📦 Product ${i + 1}: ${results[i].astroProductId}');
        }
      });
    });

    group('Product Deletion', () {
      test('should delete product from A1 Astro', () async {
        print('🔍 Testing product deletion...');

        // First create a product to delete
        final productToDelete = Product(
          id: 'delete-test-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Product to Delete',
          description: 'This product will be deleted in the test',
          price: 5.99,
          weight: 0.5,
          imageUrls: ['https://example.com/delete-test.jpg'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
        );

        // Sync it first
        final syncResult = await astroService.syncProduct(productToDelete);
        expect(syncResult.success, isTrue,
            reason: 'Product creation should succeed');

        print('📦 Created product for deletion: ${syncResult.astroProductId}');

        // Now delete it
        final deleteResult =
            await astroService.removeProduct(productToDelete.id);

        expect(deleteResult.success, isTrue,
            reason: 'Product deletion should succeed');
        expect(deleteResult.error, isNull,
            reason: 'No error should occur during deletion');

        print('✅ Product deletion passed!');
      });
    });

    group('Error Handling', () {
      test('should handle invalid product data gracefully', () async {
        print('🔍 Testing error handling with invalid data...');

        final invalidProduct = Product(
          id: '', // Invalid empty ID
          title: '', // Invalid empty title
          description: 'Test',
          price: -1.0, // Invalid negative price
          weight: 0.0,
          imageUrls: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = await astroService.syncProduct(invalidProduct);

        // Should handle the error gracefully
        expect(result.success, isFalse, reason: 'Invalid product should fail');
        expect(result.error, isNotNull, reason: 'Should return error message');

        print('✅ Error handling test passed!');
        print('❌ Expected error: ${result.error}');
      });
    });
  });
}
