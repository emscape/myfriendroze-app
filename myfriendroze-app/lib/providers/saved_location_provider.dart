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
    FirestoreService.getSavedLocations().listen(
      (locations) {
        _locations = locations;
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load saved locations: $error');
      },
    );
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
