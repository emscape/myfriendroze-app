import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/astro_integration_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  final AstroIntegrationService _astroService =
      AstroIntegrationManager.instance;

  List<Product> get products => _products;
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

  /// Sync a product with Astro site
  Future<void> _syncProductWithAstro(Product product) async {
    try {
      // Update product status to pending
      final pendingProduct = product.copyWith(
        syncStatus: ProductSyncStatus.pending,
      );
      await FirestoreService.updateProduct(pendingProduct);

      // Attempt sync
      final result = await _astroService.syncProduct(product);

      // Update product with sync result
      final updatedProduct = product.copyWith(
        syncStatus: result.success
            ? ProductSyncStatus.synced
            : ProductSyncStatus.failed,
        lastSyncAt: result.timestamp,
        syncError: result.error,
      );

      await FirestoreService.updateProduct(updatedProduct);
    } catch (e) {
      // Update product with failed status
      final failedProduct = product.copyWith(
        syncStatus: ProductSyncStatus.failed,
        lastSyncAt: DateTime.now(),
        syncError: e.toString(),
      );

      await FirestoreService.updateProduct(failedProduct);
    }
  }

  /// Manually sync a product with Astro site
  Future<bool> syncProductWithAstro(Product product) async {
    try {
      _setLoading(true);
      _setError(null);

      await _syncProductWithAstro(product);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to sync product: $e');
      return false;
    }
  }

  /// Sync all products with Astro site
  Future<bool> syncAllProductsWithAstro() async {
    try {
      _setLoading(true);
      _setError(null);

      for (final product in _products) {
        await _syncProductWithAstro(product);
        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 200));
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to sync products: $e');
      return false;
    }
  }

  void loadProducts() {
    FirestoreService.getProducts().listen(
      (products) {
        _products = products;
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load products: $error');
      },
    );
  }

  Future<bool> addProduct({
    required String title,
    required String description,
    required double price,
    required double weight,
    List<File>? imageFiles,
    List<Uint8List>? imageBytesList,
    // Backwards compatibility
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      // Handle images - support both multiple and single image for backwards compatibility
      List<String> imageUrls = [];

      if (imageBytesList != null && imageBytesList.isNotEmpty) {
        imageUrls = await StorageService.uploadMultipleImagesFromBytes(
            imageBytesList, 'products');
      } else if (imageFiles != null && imageFiles.isNotEmpty) {
        imageUrls =
            await StorageService.uploadMultipleImages(imageFiles, 'products');
      } else if (imageBytes != null) {
        // Single image backwards compatibility
        final url =
            await StorageService.uploadProductImageFromBytes(imageBytes);
        imageUrls = [url];
      } else if (imageFile != null) {
        // Single image backwards compatibility
        final url = await StorageService.uploadProductImage(imageFile);
        imageUrls = [url];
      }
      // Allow products without images - don't throw exception

      // Create product
      final Product product = Product(
        id: '', // Will be set by Firestore
        title: title,
        description: description,
        price: price,
        weight: weight,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final productId = await FirestoreService.addProduct(product);

      // Update product with the actual ID from Firestore
      final savedProduct = product.copyWith(id: productId);

      // Attempt to sync with Astro site
      await _syncProductWithAstro(savedProduct);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to add product: $e');
      return false;
    }
  }

  Future<bool> updateProduct(
    Product product, {
    List<File>? newImageFiles,
    List<Uint8List>? newImageBytesList,
    // Backwards compatibility
    File? newImageFile,
    Uint8List? newImageBytes,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      List<String> imageUrls = List.from(product.imageUrls);

      // Upload new images if provided
      if (newImageBytesList != null && newImageBytesList.isNotEmpty) {
        // Delete old images
        await StorageService.deleteMultipleImages(product.imageUrls);
        // Upload new images
        imageUrls = await StorageService.uploadMultipleImagesFromBytes(
            newImageBytesList, 'products');
      } else if (newImageFiles != null && newImageFiles.isNotEmpty) {
        // Delete old images
        await StorageService.deleteMultipleImages(product.imageUrls);
        // Upload new images
        imageUrls = await StorageService.uploadMultipleImages(
            newImageFiles, 'products');
      } else if (newImageBytes != null || newImageFile != null) {
        // Single image backwards compatibility
        await StorageService.deleteMultipleImages(product.imageUrls);
        if (newImageBytes != null) {
          final url =
              await StorageService.uploadProductImageFromBytes(newImageBytes);
          imageUrls = [url];
        } else if (newImageFile != null) {
          final url = await StorageService.uploadProductImage(newImageFile);
          imageUrls = [url];
        }
      }

      final updatedProduct = product.copyWith(
        imageUrls: imageUrls,
        updatedAt: DateTime.now(),
      );

      await FirestoreService.updateProduct(updatedProduct);

      // Attempt to sync with Astro site
      await _syncProductWithAstro(updatedProduct);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to update product: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(Product product) async {
    try {
      _setLoading(true);
      _setError(null);

      // Delete all images from storage
      if (product.imageUrls.isNotEmpty) {
        await StorageService.deleteMultipleImages(product.imageUrls);
      }

      // Delete product from Firestore
      await FirestoreService.deleteProduct(product.id);

      // Remove product from Astro site
      try {
        await _astroService.removeProduct(product.id);
      } catch (e) {
        // Log error but don't fail the deletion
        debugPrint('Failed to remove product from Astro: $e');
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to delete product: $e');
      return false;
    }
  }
}
