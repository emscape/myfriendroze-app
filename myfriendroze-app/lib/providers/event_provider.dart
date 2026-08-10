import 'dart:io';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class EventProvider extends ChangeNotifier {
  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Event> get events => _events;
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

  void loadEvents() {
    FirestoreService.getEvents().listen(
      (events) {
        _events = events;
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load events: $error');
      },
    );
  }

  Future<bool> addEvent({
    required String title,
    required String description,
    required DateTime eventDate,
    required String location,
    File? imageFile,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      String? imageUrl;
      
      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await StorageService.uploadEventImage(imageFile);
      }

      // Create event
      final Event event = Event(
        id: '', // Will be set by Firestore
        title: title,
        description: description,
        eventDate: eventDate,
        location: location,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirestoreService.addEvent(event);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to add event: $e');
      return false;
    }
  }

  Future<bool> updateEvent(Event event, {File? newImageFile}) async {
    try {
      _setLoading(true);
      _setError(null);

      String? imageUrl = event.imageUrl;
      
      // Upload new image if provided
      if (newImageFile != null) {
        // Delete old image if exists
        if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
          await StorageService.deleteImage(event.imageUrl!);
        }
        // Upload new image
        imageUrl = await StorageService.uploadEventImage(newImageFile);
      }

      final updatedEvent = event.copyWith(
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );

      await FirestoreService.updateEvent(updatedEvent);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to update event: $e');
      return false;
    }
  }

  Future<bool> deleteEvent(Event event) async {
    try {
      _setLoading(true);
      _setError(null);

      // Delete image from storage if exists
      if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
        await StorageService.deleteImage(event.imageUrl!);
      }

      // Delete event from Firestore
      await FirestoreService.deleteEvent(event.id);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to delete event: $e');
      return false;
    }
  }
}
