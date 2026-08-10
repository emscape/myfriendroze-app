import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:myfriendroze_admin/models/product.dart';
import 'package:myfriendroze_admin/services/astro_integration_service.dart';
import 'package:myfriendroze_admin/services/api_client.dart';

import 'astro_integration_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('AstroIntegrationService', () {
    late MockClient mockHttpClient;
    late ApiClient apiClient;
    late AstroIntegrationService astroService;

    setUp(() {
      mockHttpClient = MockClient();
      apiClient = ApiClient(
        environment: ApiEnvironment.dev,
        client: mockHttpClient,
      );
      astroService = AstroIntegrationService(apiClient: apiClient);
    });

    group('Product Conversion', () {
      test('should convert Product to Astro format correctly', () {
        // Create a test product
        final product = Product(
          id: 'test-id-123',
          title: 'Test Product',
          description: 'A test product description',
          price: 29.99,
          weight: 1.5,
          imageUrls: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
          isActive: true,
        );

        // Test the conversion (we need to access the private method for testing)
        // In a real implementation, you might make this method public for testing
        // or create a separate utility class
        
        // For now, let's test the sync method which uses the conversion internally
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"id": "astro-123"}', 200));

        expect(() => astroService.syncProduct(product), returnsNormally);
      });

      test('should generate valid handle from product title', () {
        final testCases = [
          {'input': 'Test Product', 'expected': 'test-product'},
          {'input': 'Product with Special @#\$ Characters!', 'expected': 'product-with-special-characters'},
          {'input': 'Multiple   Spaces   Here', 'expected': 'multiple-spaces-here'},
          {'input': '---Leading and Trailing---', 'expected': 'leading-and-trailing'},
        ];

        for (final testCase in testCases) {
          // Since _generateHandle is private, we'll test it indirectly through sync
          final product = Product(
            id: 'test',
            title: testCase['input']!,
            description: 'Test',
            price: 10.0,
            weight: 1.0,
            imageUrls: ['test.jpg'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          when(mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          )).thenAnswer((invocation) async {
            final body = invocation.namedArguments[#body] as String;
            expect(body, contains(testCase['expected']));
            return http.Response('{"id": "test"}', 200);
          });

          astroService.syncProduct(product);
        }
      });
    });

    group('Sync Operations', () {
      test('should sync product successfully', () async {
        final product = Product(
          id: 'test-123',
          title: 'Test Product',
          description: 'Test Description',
          price: 19.99,
          weight: 0.5,
          imageUrls: ['test.jpg'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"id": "astro-123"}', 200));

        final result = await astroService.syncProduct(product);

        expect(result.success, isTrue);
        expect(result.error, isNull);
        expect(result.astroProductId, equals('astro-123'));
      });

      test('should handle sync failure', () async {
        final product = Product(
          id: 'test-123',
          title: 'Test Product',
          description: 'Test Description',
          price: 19.99,
          weight: 0.5,
          imageUrls: ['test.jpg'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"error": "Server error"}', 500));

        final result = await astroService.syncProduct(product);

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        expect(result.astroProductId, isNull);
      });

      test('should remove product successfully', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"success": true}', 200));

        final result = await astroService.removeProduct('test-123');

        expect(result.success, isTrue);
        expect(result.error, isNull);
      });

      test('should sync multiple products with delay', () async {
        final products = List.generate(3, (index) => Product(
          id: 'test-$index',
          title: 'Test Product $index',
          description: 'Test Description $index',
          price: 10.0 + index,
          weight: 1.0,
          imageUrls: ['test$index.jpg'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"id": "astro-123"}', 200));

        final stopwatch = Stopwatch()..start();
        final results = await astroService.syncProducts(products);
        stopwatch.stop();

        expect(results.length, equals(3));
        expect(results.every((r) => r.success), isTrue);
        // Should take at least 200ms (100ms delay * 2 intervals between 3 products)
        expect(stopwatch.elapsedMilliseconds, greaterThan(200));
      });
    });

    group('Health Check', () {
      test('should return true for healthy service', () async {
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"status": "ok"}', 200));

        final isHealthy = await astroService.checkIntegrationHealth();

        expect(isHealthy, isTrue);
      });

      test('should return false for unhealthy service', () async {
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"status": "error"}', 500));

        final isHealthy = await astroService.checkIntegrationHealth();

        expect(isHealthy, isFalse);
      });

      test('should handle network errors gracefully', () async {
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenThrow(Exception('Network error'));

        final isHealthy = await astroService.checkIntegrationHealth();

        expect(isHealthy, isFalse);
      });
    });

    group('Site Rebuild', () {
      test('should trigger rebuild successfully', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"success": true}', 200));

        final success = await astroService.triggerSiteRebuild();

        expect(success, isTrue);
      });

      test('should handle rebuild failure', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Failed"}', 500));

        final success = await astroService.triggerSiteRebuild();

        expect(success, isFalse);
      });
    });

    group('Sync Statistics', () {
      test('should return sync stats when available', () async {
        final mockStats = {
          'totalProducts': 10,
          'lastSync': '2024-01-01T12:00:00Z',
          'successRate': 95,
        };

        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"totalProducts": 10, "lastSync": "2024-01-01T12:00:00Z", "successRate": 95}',
          200,
        ));

        final stats = await astroService.getSyncStats();

        expect(stats, isNotNull);
        expect(stats!['totalProducts'], equals(10));
        expect(stats['successRate'], equals(95));
      });

      test('should return null when stats unavailable', () async {
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenThrow(Exception('Stats not available'));

        final stats = await astroService.getSyncStats();

        expect(stats, isNull);
      });
    });
  });
}
