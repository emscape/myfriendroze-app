// cloud_firestore re-exports an internal `Order` enum (query sort direction)
// from cloud_firestore_platform_interface that collides with this file's own
// Order class -- hidden to avoid an ambiguous-import compile error.
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

class Customer {
  final String email;
  final String name;
  final String? phone;

  Customer({required this.email, required this.name, this.phone});

  factory Customer.fromMap(Map<String, dynamic> data) {
    return Customer(
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
    );
  }
}

class OrderItem {
  final String name;
  final int qty;
  final double amountTotal;

  OrderItem({required this.name, required this.qty, required this.amountTotal});

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      name: data['name'] ?? '',
      qty: (data['qty'] as num?)?.toInt() ?? 0,
      amountTotal: (data['amountTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ShippingAddress {
  final String name;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  ShippingAddress({
    required this.name,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });

  factory ShippingAddress.fromMap(Map<String, dynamic> data) {
    return ShippingAddress(
      name: data['name'] ?? '',
      line1: data['line1'] ?? '',
      line2: data['line2'],
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      postalCode: data['postalCode'] ?? '',
      country: data['country'] ?? '',
    );
  }
}

class ShippingDetails {
  final String trackingNumber;
  final String carrier;
  final String? trackingUrl;
  final String? estimatedDelivery;

  ShippingDetails({
    required this.trackingNumber,
    required this.carrier,
    this.trackingUrl,
    this.estimatedDelivery,
  });

  factory ShippingDetails.fromMap(Map<String, dynamic> data) {
    return ShippingDetails(
      trackingNumber: data['trackingNumber'] ?? '',
      carrier: data['carrier'] ?? '',
      trackingUrl: data['trackingUrl'],
      estimatedDelivery: data['estimatedDelivery'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trackingNumber': trackingNumber,
      'carrier': carrier,
      if (trackingUrl != null) 'trackingUrl': trackingUrl,
      if (estimatedDelivery != null) 'estimatedDelivery': estimatedDelivery,
    };
  }
}

/// Order document as written by firebase/functions/lib/orderFromSession.js's
/// sessionToOrderData and updated by orderShipped.js -- read-only from this
/// app's perspective (no toFirestore()): writes only ever happen through the
/// sendOrderShippedNotification callable, never a direct client write.
class Order {
  final String id;
  final String status;
  final String stripeSessionId;
  final String stripePaymentIntentId;
  final Customer customer;
  final List<OrderItem> items;
  final double total;
  final String currency;
  final ShippingAddress? shippingAddress;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ShippingDetails? shippingDetails;
  final DateTime? shippedAt;
  final DateTime? shippedNotificationSentAt;

  Order({
    required this.id,
    required this.status,
    required this.stripeSessionId,
    required this.stripePaymentIntentId,
    required this.customer,
    required this.items,
    required this.total,
    required this.currency,
    this.shippingAddress,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.shippingDetails,
    this.shippedAt,
    this.shippedNotificationSentAt,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final shippingAddressData = data['shippingAddress'] as Map<String, dynamic>?;
    final shippingDetailsData = data['shippingDetails'] as Map<String, dynamic>?;

    return Order(
      id: doc.id,
      status: data['status'] ?? '',
      stripeSessionId: data['stripeSessionId'] ?? doc.id,
      stripePaymentIntentId: data['stripePaymentIntentId'] ?? '',
      customer: Customer.fromMap(data['customer'] ?? {}),
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'usd',
      shippingAddress:
          shippingAddressData != null ? ShippingAddress.fromMap(shippingAddressData) : null,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shippingDetails:
          shippingDetailsData != null ? ShippingDetails.fromMap(shippingDetailsData) : null,
      shippedAt: (data['shippedAt'] as Timestamp?)?.toDate(),
      shippedNotificationSentAt: (data['shippedNotificationSentAt'] as Timestamp?)?.toDate(),
    );
  }
}
