import 'dart:async';
import 'package:flutter/material.dart';
import '../models/saved_location.dart';
import '../services/firestore_service.dart';

// Roze-entered venue addresses she can reuse across events (Jackalope
// Pasadena, Common Space Brewing, etc.) instead of retyping them each time
// — same simple stream-backed CRUD shape as EventProvider/GalleryProvider.
class SavedLocationProvider extends ChangeNotifier {
  List<SavedLocation> _locations = [];
  bool _isLoading = false;
  String? _errorMessage;
  // loadLocations() can be called every time the add/edit event form opens
  // (this provider is a single long-lived instance, not recreated per
  // screen) — tracked so each call replaces the previous listener instead
  // of accumulating one Firestore subscription per open.
  StreamSubscription<List<SavedLocation>>? _subscription;

  List<SavedLocation> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  void loadLocations() {
    _subscription?.cancel();
    _subscription = FirestoreService.getSavedLocations().listen(
      (locations) {
        _locations = locations;
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load saved locations: $error');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<bool> addLocation({required String name, required String address}) async {
    try {
      _setLoading(true);
      _setError(null);

      await FirestoreService.addSavedLocation(
        SavedLocation(id: '', name: name, address: address),
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to save location: $e');
      return false;
    }
  }

  Future<bool> deleteLocation(SavedLocation location) async {
    try {
      _setLoading(true);
      _setError(null);

      await FirestoreService.deleteSavedLocation(location.id);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to delete saved location: $e');
      return false;
    }
  }
}
