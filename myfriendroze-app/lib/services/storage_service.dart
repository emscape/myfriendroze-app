import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static FirebaseStorage _storage = FirebaseStorage.instance;
  static const Uuid _uuid = Uuid();

  /// Swaps the Storage instance used by this service. Test-only — lets unit
  /// tests inject a `MockFirebaseStorage` instead of talking to a real
  /// Firebase project. Never call this from production code.
  @visibleForTesting
  static void setStorageInstance(FirebaseStorage instance) {
    _storage = instance;
  }

  static Future<String> uploadProductImage(File imageFile) async {
    try {
      final String fileName = '${_uuid.v4()}.jpg';
      final Reference ref = _storage.ref().child('products').child(fileName);

      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload product image: $e');
    }
  }

  static Future<String> uploadProductImageFromBytes(Uint8List bytes) async {
    try {
      final String fileName = '${_uuid.v4()}.jpg';
      final Reference ref = _storage.ref().child('products').child(fileName);

      final UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload product image (bytes): $e');
    }
  }

  static Future<String> uploadEventImage(File imageFile) async {
    try {
      final String fileName = '${_uuid.v4()}.jpg';
      final Reference ref = _storage.ref().child('events').child(fileName);

      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload event image: $e');
    }
  }

  static Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  static Future<List<String>> uploadMultipleImages(List<File> imageFiles, String folder) async {
    try {
      final List<String> downloadUrls = [];

      for (final File imageFile in imageFiles) {
        final String fileName = '${_uuid.v4()}.jpg';
        final Reference ref = _storage.ref().child(folder).child(fileName);

        final UploadTask uploadTask = ref.putFile(
          imageFile,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );

        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  static Future<List<String>> uploadMultipleImagesFromBytes(List<Uint8List> imageBytesList, String folder) async {
    try {
      final List<String> downloadUrls = [];

      for (final Uint8List imageBytes in imageBytesList) {
        final String fileName = '${_uuid.v4()}.jpg';
        final Reference ref = _storage.ref().child(folder).child(fileName);

        final UploadTask uploadTask = ref.putData(
          imageBytes,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );

        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('Failed to upload images (bytes): $e');
    }
  }

  static Future<void> deleteMultipleImages(List<String> imageUrls) async {
    try {
      for (final String imageUrl in imageUrls) {
        if (imageUrl.isNotEmpty) {
          await deleteImage(imageUrl);
        }
      }
    } catch (e) {
      throw Exception('Failed to delete multiple images: $e');
    }
  }
}
