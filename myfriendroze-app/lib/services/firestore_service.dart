import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/event.dart';
import '../models/gallery_photo.dart';

class FirestoreService {
  static FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Swaps the Firestore instance used by this service. Test-only — lets
  /// unit tests inject a `FakeFirebaseFirestore` instead of talking to a
  /// real Firebase project. Never call this from production code.
  @visibleForTesting
  static void setFirestoreInstance(FirebaseFirestore instance) {
    _firestore = instance;
  }

  // Products collection reference
  static CollectionReference get _productsCollection =>
      _firestore.collection('products');

  // Events collection reference
  static CollectionReference get _eventsCollection =>
      _firestore.collection('events');

  // Gallery collection reference
  static CollectionReference get _galleryCollection =>
      _firestore.collection('gallery');

  // Product operations
  static Future<String> addProduct(Product product) async {
    try {
      final docRef = await _productsCollection.add(product.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  static Future<void> updateProduct(Product product) async {
    try {
      await _productsCollection.doc(product.id).update(product.toFirestore());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  static Future<void> deleteProduct(String productId) async {
    try {
      await _productsCollection.doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  static Stream<List<Product>> getProducts() {
    return _productsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList());
  }

  static Future<Product?> getProduct(String productId) async {
    try {
      final doc = await _productsCollection.doc(productId).get();
      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  // Event operations
  static Future<String> addEvent(Event event) async {
    try {
      final docRef = await _eventsCollection.add(event.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add event: $e');
    }
  }

  static Future<void> updateEvent(Event event) async {
    try {
      await _eventsCollection.doc(event.id).update(event.toFirestore());
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  static Future<void> deleteEvent(String eventId) async {
    try {
      await _eventsCollection.doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  static Stream<List<Event>> getEvents() {
    return _eventsCollection
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromFirestore(doc))
            .toList());
  }

  static Future<Event?> getEvent(String eventId) async {
    try {
      final doc = await _eventsCollection.doc(eventId).get();
      if (doc.exists) {
        return Event.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get event: $e');
    }
  }

  // Gallery operations
  static Future<String> addGalleryPhoto(GalleryPhoto photo) async {
    try {
      final docRef = await _galleryCollection.add(photo.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add gallery photo: $e');
    }
  }

  static Future<void> updateGalleryPhoto(GalleryPhoto photo) async {
    try {
      await _galleryCollection.doc(photo.id).update(photo.toFirestore());
    } catch (e) {
      throw Exception('Failed to update gallery photo: $e');
    }
  }

  static Future<void> deleteGalleryPhoto(String photoId) async {
    try {
      await _galleryCollection.doc(photoId).delete();
    } catch (e) {
      throw Exception('Failed to delete gallery photo: $e');
    }
  }

  static Stream<List<GalleryPhoto>> getGalleryPhotos() {
    return _galleryCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GalleryPhoto.fromFirestore(doc))
            .toList());
  }

  static Future<GalleryPhoto?> getGalleryPhoto(String photoId) async {
    try {
      final doc = await _galleryCollection.doc(photoId).get();
      if (doc.exists) {
        return GalleryPhoto.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get gallery photo: $e');
    }
  }
}
