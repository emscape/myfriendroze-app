import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/firestore_service.dart';
import '../services/order_shipping_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderShippingService _shippingService;

  OrderProvider({OrderShippingService? shippingService})
      : _shippingService = shippingService ?? OrderShippingService();

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

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
    FirestoreService.getOrders().listen(
      (orders) {
        _orders = orders;
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load orders: $error');
      },
    );
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
