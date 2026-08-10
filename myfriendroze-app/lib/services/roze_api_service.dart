import 'package:firebase_auth/firebase_auth.dart';
import 'api_client.dart';
import '../models/order.dart';
import '../models/subscription.dart';

/// Service for handling ROZE API interactions
/// Based on A1's API specifications: v1.0.0
class RozeApiService {
  final ApiClient _apiClient;
  final FirebaseAuth _firebaseAuth;

  RozeApiService({
    ApiClient? apiClient,
    FirebaseAuth? firebaseAuth,
  })  : _apiClient = apiClient ?? ApiClientManager.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    _setupAuthTokenListener();
  }

  /// Setup listener for Firebase Auth token changes
  void _setupAuthTokenListener() {
    _firebaseAuth.authStateChanges().listen((user) async {
      if (user != null) {
        // Get the ID token and set it in the API client
        final idToken = await user.getIdToken();
        _apiClient.setAuthToken(idToken);
      } else {
        // Clear token when user logs out
        _apiClient.setAuthToken(null);
      }
    });
  }

  /// Check API health status
  /// Endpoint: GET /healthz
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      return await _apiClient.get('/healthz');
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new order
  /// Endpoint: POST /v1/orders
  /// Requires authentication (Firebase Auth)
  Future<OrderResponse> createOrder({
    required Customer customer,
    required List<OrderItem> items,
    required double total,
    String currency = 'USD',
    String? notes,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const ApiException(
          message: 'User must be authenticated to create orders',
          code: 'UNAUTHENTICATED',
        );
      }

      final body = {
        'customer': customer.toJson(),
        'items': items.map((item) => item.toJson()).toList(),
        'total': total,
        'currency': currency,
        if (notes != null) 'notes': notes,
      };

      final response = await _apiClient.post('/v1/orders', body: body);
      return OrderResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get order by ID
  /// Endpoint: GET /v1/orders/{orderId}
  /// Requires authentication
  Future<Order> getOrder(String orderId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const ApiException(
          message: 'User must be authenticated to fetch orders',
          code: 'UNAUTHENTICATED',
        );
      }

      final response = await _apiClient.get('/v1/orders/$orderId');
      return Order.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// List orders for authenticated user
  /// Endpoint: GET /v1/orders
  /// Requires authentication
  Future<List<Order>> listOrders() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const ApiException(
          message: 'User must be authenticated to list orders',
          code: 'UNAUTHENTICATED',
        );
      }

      final response = await _apiClient.get('/v1/orders');
      final List<dynamic> orders = response['orders'] ?? [];
      return orders
          .map((order) => Order.fromJson(order as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Subscribe to newsletter or service
  /// Endpoint: POST /v1/subscribe
  /// Can be called without authentication
  Future<SubscriptionResponse> subscribe({
    required String email,
    String? name,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final body = {
        'email': email,
        if (name != null) 'name': name,
        if (metadata != null) ...metadata,
      };

      final response = await _apiClient.post('/v1/subscribe', body: body);
      return SubscriptionResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel a subscription
  /// Endpoint: DELETE /v1/subscribe/{subscriptionId}
  /// Can be called without authentication for token-based cancellation
  Future<Map<String, dynamic>> cancelSubscription(String subscriptionId) async {
    try {
      return await _apiClient.delete('/v1/subscribe/$subscriptionId');
    } catch (e) {
      rethrow;
    }
  }

  /// Get current auth token
  Future<String?> getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  /// Check if user is authenticated
  bool isAuthenticated() => _firebaseAuth.currentUser != null;

  /// Manually refresh auth token (useful when token may have expired)
  Future<void> refreshAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final idToken = await user.getIdToken(true);
      _apiClient.setAuthToken(idToken);
    }
  }
}
