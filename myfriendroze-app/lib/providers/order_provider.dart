import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/firestore_service.dart';
import '../services/order_shipping_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderShippingService _shippingService;
  final Stream<List<Order>> Function() _ordersStreamFactory;

  OrderProvider({
    OrderShippingService? shippingService,
    // Injectable so tests can exercise loadOrders()'s onError branch with a
    // stream that actually errors -- FakeFirebaseFirestore's real snapshots()
    // stream doesn't have a way to simulate a Firestore-level failure.
    Stream<List<Order>> Function()? ordersStreamFactory,
  })  : _shippingService = shippingService ?? OrderShippingService(),
        _ordersStreamFactory = ordersStreamFactory ?? FirestoreService.getOrders;

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  // loadOrders() can be called every time OrdersScreen is opened or retried
  // (this provider is a single long-lived instance, not recreated per
  // screen) -- tracked so each call replaces the previous listener instead
  // of accumulating one Firestore subscription per open (matches
  // SavedLocationProvider's pattern).
  StreamSubscription<List<Order>>? _subscription;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Order> get ordersNeedingShipping =>
      _orders.where((order) => order.status == 'paid').toList();

  List<Order> get shippedOrders =>
      _orders.where((order) => order.status == 'shipped').toList();

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }

  void loadOrders() {
    _subscription?.cancel();
    _subscription = _ordersStreamFactory().listen(
      (orders) {
        _orders = orders;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load orders: $error');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Marks an order shipped via the sendOrderShippedNotification callable.
  /// No client-side double-tap guarding -- the callable is already
  /// idempotent (atomic Firestore transaction claim, see orderShipped.js).
  Future<bool> markShipped(
    String orderId, {
    required String trackingNumber,
    required String carrier,
    String? trackingUrl,
    String? estimatedDelivery,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _shippingService.markShipped(
        orderId: orderId,
        shippingDetails: {
          'trackingNumber': trackingNumber,
          'carrier': carrier,
          if (trackingUrl != null) 'trackingUrl': trackingUrl,
          if (estimatedDelivery != null) 'estimatedDelivery': estimatedDelivery,
        },
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _isLoading = false;
      _setError('Failed to mark order shipped: $e');
      return false;
    }
  }
}
