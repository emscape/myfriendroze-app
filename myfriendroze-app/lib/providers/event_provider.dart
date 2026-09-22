import 'dart:io';
import 'dart:typed_data';
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
    DateTime? endDate,
    required String location,
    File? imageFile,
    Uint8List? imageBytes,
    String? link,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      String? imageUrl;

      // Bytes checked first: on web, dart:io File paths from image_picker
      // don't correspond to a real filesystem, so uploadEventImage's
      // putFile() throws UnimplementedError there — the caller must use
      // readAsBytes() on web and pass imageBytes instead (see
      // add_event_screen.dart, matching the same File/bytes split already
      // used for products and gallery photos).
      if (imageBytes != null) {
        imageUrl = await StorageService.uploadEventImageFromBytes(imageBytes);
      } else if (imageFile != null) {
        imageUrl = await StorageService.uploadEventImage(imageFile);
      }

      // Create event
      final Event event = Event(
        id: '', // Will be set by Firestore
        title: title,
        description: description,
        eventDate: eventDate,
        endDate: endDate,
        location: location,
        imageUrl: imageUrl,
        link: link,
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

  Future<bool> updateEvent(
    Event event, {
    File? newImageFile,
    Uint8List? newImageBytes,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final oldImageUrl = event.imageUrl;
      String? imageUrl = event.imageUrl;
      // Whether a replacement was attempted at all, regardless of which
      // form (bytes on web, file on native) — used below instead of
      // repeating both null checks at each call site.
      final hasReplacement = newImageBytes != null || newImageFile != null;

      // Upload the replacement BEFORE touching the old image — if the
      // upload throws, the event keeps pointing at its existing (still
      // live) photo instead of an already-deleted Storage object. Bytes
      // checked first — see addEvent's comment on why.
      if (newImageBytes != null) {
        imageUrl = await StorageService.uploadEventImageFromBytes(newImageBytes);
      } else if (newImageFile != null) {
        imageUrl = await StorageService.uploadEventImage(newImageFile);
      }

      final updatedEvent = event.copyWith(
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );

      try {
        await FirestoreService.updateEvent(updatedEvent);
      } catch (e) {
        // A client-side exception here doesn't prove the write never
        // landed — it can commit server-side while the acknowledgment is
        // what actually fails/times out. Deleting the replacement on that
        // assumption alone could break a live event's image if the write
        // really did commit. Re-read the doc and only clean up the
        // replacement if it demonstrably ISN'T the one Firestore has;
        // if we can't even confirm that, leave it alone — an orphaned
        // Storage object is far less harmful than a broken live photo.
        if (hasReplacement && imageUrl != null && imageUrl != oldImageUrl) {
          try {
            final currentDoc = await FirestoreService.getEvent(event.id);
            if (currentDoc != null && currentDoc.imageUrl != imageUrl) {
              await StorageService.deleteImage(imageUrl);
            }
          } catch (_) {
            // Ignored — see comment above: default to not deleting.
          }
        }
        rethrow;
      }

      // Only clean up the OLD image once the new one is safely live in
      // Firestore. Best-effort: the event update already succeeded and is
      // showing the new photo, so a leftover orphaned Storage object isn't
      // worth failing the whole edit over.
      if (hasReplacement && oldImageUrl != null && oldImageUrl.isNotEmpty) {
        try {
          await StorageService.deleteImage(oldImageUrl);
        } catch (_) {
          // Ignored — see comment above.
        }
      }

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
