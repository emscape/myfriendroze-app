import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/gallery_photo.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class GalleryProvider extends ChangeNotifier {
  List<GalleryPhoto> _photos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<GalleryPhoto> get photos => _photos;
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

  void loadGalleryPhotos() {
    FirestoreService.getGalleryPhotos().listen(
      (photos) {
        _photos = photos;
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load gallery photos: $error');
      },
    );
  }

  Future<bool> addGalleryPhoto({
    required String altText,
    String? caption,
    String? link,
    List<File>? imageFiles,
    List<Uint8List>? imageBytesList,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      String? imageUrl;
      if (imageBytesList != null && imageBytesList.isNotEmpty) {
        final urls = await StorageService.uploadMultipleImagesFromBytes(
            imageBytesList, 'gallery');
        imageUrl = urls.first;
      } else if (imageFiles != null && imageFiles.isNotEmpty) {
        final urls =
            await StorageService.uploadMultipleImages(imageFiles, 'gallery');
        imageUrl = urls.first;
      }

      // A gallery entry with no photo is meaningless — unlike products,
      // fail fast instead of silently allowing an imageless doc.
      if (imageUrl == null) {
        _setLoading(false);
        _setError('A photo is required to add a gallery entry.');
        return false;
      }

      final now = DateTime.now();
      final photo = GalleryPhoto(
        id: '', // Will be set by Firestore
        imageUrl: imageUrl,
        altText: altText,
        caption: caption,
        link: link,
        createdAt: now,
        updatedAt: now,
      );

      await FirestoreService.addGalleryPhoto(photo);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to add gallery photo: $e');
      return false;
    }
  }

  Future<bool> updateGalleryPhoto(
    GalleryPhoto photo, {
    String? altText,
    String? caption,
    String? link,
    List<File>? newImageFiles,
    List<Uint8List>? newImageBytesList,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      String imageUrl = photo.imageUrl;

      if (newImageBytesList != null && newImageBytesList.isNotEmpty) {
        await StorageService.deleteMultipleImages([photo.imageUrl]);
        final urls = await StorageService.uploadMultipleImagesFromBytes(
            newImageBytesList, 'gallery');
        imageUrl = urls.first;
      } else if (newImageFiles != null && newImageFiles.isNotEmpty) {
        await StorageService.deleteMultipleImages([photo.imageUrl]);
        final urls = await StorageService.uploadMultipleImages(
            newImageFiles, 'gallery');
        imageUrl = urls.first;
      }

      final updatedPhoto = photo.copyWith(
        imageUrl: imageUrl,
        altText: altText,
        caption: caption,
        link: link,
        updatedAt: DateTime.now(),
      );

      await FirestoreService.updateGalleryPhoto(updatedPhoto);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to update gallery photo: $e');
      return false;
    }
  }

  Future<bool> deleteGalleryPhoto(GalleryPhoto photo) async {
    try {
      _setLoading(true);
      _setError(null);

      await StorageService.deleteMultipleImages([photo.imageUrl]);
      await FirestoreService.deleteGalleryPhoto(photo.id);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to delete gallery photo: $e');
      return false;
    }
  }
}
