import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import '../services/roze_api_service.dart';

/// Provider for managing subscriptions
class SubscriptionProvider extends ChangeNotifier {
  final RozeApiService _apiService;

  SubscriptionProvider({RozeApiService? apiService})
      : _apiService = apiService ?? RozeApiService();

  // State
  Subscription? _currentSubscription;
  bool _isLoading = false;
  String? _error;
  bool _isSubscribed = false;

  // Getters
  Subscription? get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isSubscribed => _isSubscribed;

  /// Subscribe to newsletter or service
  Future<bool> subscribe({
    required String email,
    String? name,
    Map<String, dynamic>? metadata,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.subscribe(
        email: email,
        name: name,
        metadata: metadata,
      );

      _currentSubscription = response.subscription;
      _isSubscribed = true;

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

  /// Cancel subscription
  Future<bool> cancelSubscription(String subscriptionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.cancelSubscription(subscriptionId);

      _currentSubscription = null;
      _isSubscribed = false;

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

  /// Clear subscription
  void clearSubscription() {
    _currentSubscription = null;
    _isSubscribed = false;
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
