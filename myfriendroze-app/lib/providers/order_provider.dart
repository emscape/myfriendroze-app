import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/roze_api_service.dart';

/// Provider for managing orders and order operations
class OrderProvider extends ChangeNotifier {
  final RozeApiService _apiService;

  OrderProvider({RozeApiService? apiService})
      : _apiService = apiService ?? RozeApiService();

  // State
  List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  /// Create a new order
  Future<bool> createOrder({
    required Customer customer,
    required List<OrderItem> items,
    required double total,
    String currency = 'USD',
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createOrder(
        customer: customer,
        items: items,
        total: total,
        currency: currency,
        notes: notes,
      );

      _currentOrder = response.order;
      _orders.insert(0, response.order); // Add to top of list

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch order by ID
  Future<bool> fetchOrder(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final order = await _apiService.getOrder(orderId);
      _currentOrder = order;

      // Update in list if exists
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders[index] = order;
      } else {
        _orders.add(order);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch all orders for authenticated user
  Future<bool> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _apiService.listOrders();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear current order
  void clearCurrentOrder() {
    _currentOrder = null;
    _error = null;
    notifyListeners();
  }

  /// Clear all orders
  void clearOrders() {
    _orders = [];
    _currentOrder = null;
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
