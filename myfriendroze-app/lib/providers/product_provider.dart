import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

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
    double heightIn = 0.0,
    double widthIn = 0.0,
    double depthIn = 0.0,
    double shippingBoxHeightIn = 0.0,
    double shippingBoxWidthIn = 0.0,
    double shippingBoxDepthIn = 0.0,
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
        heightIn: heightIn,
        widthIn: widthIn,
        depthIn: depthIn,
        shippingBoxHeightIn: shippingBoxHeightIn,
        shippingBoxWidthIn: shippingBoxWidthIn,
        shippingBoxDepthIn: shippingBoxDepthIn,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirestoreService.addProduct(product);

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

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to update product: $e');
      return false;
    }
  }

  /// Marks a product in-stock/sold-out. Kept as its own entry point (rather
  /// than routing sold-out toggles through the general updateProduct form
  /// flow) since it's a one-tap admin action with no image/text changes to
  /// make alongside it. Read by product-mapping.js's docToProduct on the
  /// site and enforced at the checkout boundary in
  /// firebase/functions/lib/pricing.js.
  Future<bool> setInStock(Product product, bool inStock) async {
    try {
      _setLoading(true);
      _setError(null);

      final updated = product.copyWith(
        inStock: inStock,
        updatedAt: DateTime.now(),
      );
      await FirestoreService.updateProduct(updated);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to update stock status: $e');
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

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to delete product: $e');
      return false;
    }
  }
}
