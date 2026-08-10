import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Direct tests against A1's Astro endpoints
/// These tests bypass the Flutter service layer and test A1's API directly
void main() {
  group('Direct Astro API Tests', () {
    const baseUrl = 'http://localhost:4321/api';

    group('Health Check', () {
      test('should get health status from A1 Astro server', () async {
        try {
          final response = await http.get(
            Uri.parse('$baseUrl/health'),
            headers: {'Content-Type': 'application/json'},
          );

          expect(response.statusCode, equals(200));

          final healthData = json.decode(response.body);
          expect(healthData['status'], equals('ok'));

          // ignore: avoid_print
          print('✅ Health check passed!');
          // ignore: avoid_print
          print('📊 Health data: ${json.encode(healthData)}');
        } catch (e) {
          fail('Health check failed: $e');
        }
      });
    });

    group('Product Sync', () {
      test('should sync single product to A1 Astro', () async {
        final testProduct = {
          'id': 'direct-test-${DateTime.now().millisecondsSinceEpoch}',
          'title': 'Direct Test Product',
          'description': 'This is a direct test product',
          'price': 29.99,
          'weight': 1.5,
          'imageUrls': ['https://example.com/test.jpg'],
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        try {
          final response = await http.post(
            Uri.parse('$baseUrl/products/sync'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(testProduct),
          );

          expect(response.statusCode,
              anyOf([200, 201])); // Accept both OK and Created

          final responseData = json.decode(response.body);
          expect(responseData['success'], isTrue);

          // ignore: avoid_print
          print('✅ Product sync passed!');
          // ignore: avoid_print
          print('📦 Response: ${json.encode(responseData)}');
        } catch (e) {
          fail('Product sync failed: $e');
        }
      });

      test('should sync multiple products via bulk endpoint', () async {
        final testProducts = List.generate(
            2,
            (index) => {
                  'id':
                      'bulk-direct-test-${DateTime.now().millisecondsSinceEpoch}-$index',
                  'title': 'Bulk Direct Test Product ${index + 1}',
                  'description': 'Bulk test product #${index + 1}',
                  'price': 10.0 + (index * 5),
                  'weight': 1.0 + index,
                  'imageUrls': ['https://example.com/bulk-$index.jpg'],
                  'isActive': true,
                  'createdAt': DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                });

        try {
          final response = await http.post(
            Uri.parse('$baseUrl/products/bulk-sync'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'products': testProducts}),
          );

          expect(response.statusCode,
              anyOf([200, 207])); // 200 for success, 207 for partial

          final responseData = json.decode(response.body);
          expect(responseData['summary'], isNotNull);

          // ignore: avoid_print
          print('✅ Bulk sync passed!');
          // ignore: avoid_print
          print('📦 Response: ${json.encode(responseData)}');
        } catch (e) {
          fail('Bulk sync failed: $e');
        }
      });
    });

    group('Product Deletion', () {
      test('should delete product from A1 Astro', () async {
        // First create a product to delete
        final productId =
            'delete-direct-test-${DateTime.now().millisecondsSinceEpoch}';
        final testProduct = {
          'id': productId,
          'title': 'Product to Delete',
          'description': 'This will be deleted',
          'price': 5.99,
          'weight': 0.5,
          'imageUrls': ['https://example.com/delete.jpg'],
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        try {
          // Create the product first
          final createResponse = await http.post(
            Uri.parse('$baseUrl/products/sync'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(testProduct),
          );

          expect(createResponse.statusCode,
              anyOf([200, 201])); // Accept both OK and Created

          // Now delete it
          final deleteResponse = await http.delete(
            Uri.parse('$baseUrl/products/$productId'),
            headers: {'Content-Type': 'application/json'},
          );

          expect(deleteResponse.statusCode,
              anyOf([200, 201])); // Accept both OK and Created

          final responseData = json.decode(deleteResponse.body);
          expect(responseData['success'], isTrue);

          // ignore: avoid_print
          print('✅ Product deletion passed!');
          // ignore: avoid_print
          print('🗑️ Response: ${json.encode(responseData)}');
        } catch (e) {
          fail('Product deletion failed: $e');
        }
      });
    });

    group('Error Handling', () {
      test('should handle invalid product data', () async {
        final invalidProduct = {
          'id': '', // Invalid empty ID
          'title': '', // Invalid empty title
          'description': 'Test',
          'price': -1.0, // Invalid negative price
          'weight': 0.0,
          'imageUrls': [],
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        try {
          final response = await http.post(
            Uri.parse('$baseUrl/products/sync'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(invalidProduct),
          );

          // Should return an error status
          expect(response.statusCode, anyOf([400, 422]));

          final responseData = json.decode(response.body);
          expect(responseData['error'], isNotNull);

          // ignore: avoid_print
          print('✅ Error handling passed!');
          // ignore: avoid_print
          print('❌ Expected error: ${responseData['error']}');
        } catch (e) {
          fail('Error handling test failed: $e');
        }
      });
    });
  });
}
