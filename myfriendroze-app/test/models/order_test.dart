import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myfriendroze_admin/models/order.dart';

void main() {
  group('Order.fromFirestore', () {
    test('parses a paid order awaiting shipment', () async {
      final firestore = FakeFirebaseFirestore();
      final ref = firestore.collection('orders').doc('cs_test_abc123');
      await ref.set({
        'status': 'paid',
        'stripeSessionId': 'cs_test_abc123',
        'stripePaymentIntentId': 'pi_test_xyz',
        'customer': {
          'email': 'buyer@example.com',
          'name': 'Jane Buyer',
          'phone': '555-0100',
        },
        'items': [
          {'name': 'Mug', 'qty': 2, 'amountTotal': 36.0},
          {'name': 'Bowl', 'qty': 1, 'amountTotal': 28.0},
        ],
        'total': 64.0,
        'currency': 'usd',
        'shippingAddress': {
          'name': 'Jane Buyer',
          'line1': '123 Main St',
          'line2': null,
          'city': 'Long Beach',
          'state': 'CA',
          'postalCode': '90802',
          'country': 'US',
        },
        'notes': null,
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 20, 10)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 9, 20, 10)),
      });

      final snapshot = await ref.get();
      final order = Order.fromFirestore(snapshot);

      expect(order.id, 'cs_test_abc123');
      expect(order.status, 'paid');
      expect(order.stripeSessionId, 'cs_test_abc123');
      expect(order.customer.email, 'buyer@example.com');
      expect(order.customer.name, 'Jane Buyer');
      expect(order.items, hasLength(2));
      expect(order.items.first.name, 'Mug');
      expect(order.items.first.qty, 2);
      expect(order.items.first.amountTotal, 36.0);
      expect(order.total, 64.0);
      expect(order.currency, 'usd');
      expect(order.shippingAddress?.city, 'Long Beach');
      expect(order.notes, isNull);
      expect(order.createdAt, DateTime(2026, 9, 20, 10));
      expect(order.shippingDetails, isNull);
      expect(order.shippedAt, isNull);
      expect(order.shippedNotificationSentAt, isNull);
    });

    test('parses a shipped order with full shipping details', () async {
      final firestore = FakeFirebaseFirestore();
      final ref = firestore.collection('orders').doc('cs_test_shipped');
      await ref.set({
        'status': 'shipped',
        'stripeSessionId': 'cs_test_shipped',
        'stripePaymentIntentId': 'pi_test_shipped',
        'customer': {
          'email': 'buyer2@example.com',
          'name': 'Sam Buyer',
          'phone': null,
        },
        'items': [
          {'name': 'Vase', 'qty': 1, 'amountTotal': 45.0},
        ],
        'total': 45.0,
        'currency': 'usd',
        'shippingAddress': {
          'name': 'Sam Buyer',
          'line1': '456 Oak Ave',
          'line2': 'Apt 2',
          'city': 'Pasadena',
          'state': 'CA',
          'postalCode': '91101',
          'country': 'US',
        },
        'notes': 'Leave at front door',
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 18, 9)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 9, 21, 14)),
        'shippingDetails': {
          'trackingNumber': '1Z999AA10123456784',
          'carrier': 'UPS',
          'trackingUrl': 'https://www.ups.com/track?tracknum=1Z999AA10123456784',
          'estimatedDelivery': '2026-09-25',
        },
        'shippedAt': Timestamp.fromDate(DateTime(2026, 9, 21, 14)),
        'shippedNotificationSentAt': Timestamp.fromDate(DateTime(2026, 9, 21, 14)),
      });

      final snapshot = await ref.get();
      final order = Order.fromFirestore(snapshot);

      expect(order.status, 'shipped');
      expect(order.notes, 'Leave at front door');
      expect(order.shippingDetails?.trackingNumber, '1Z999AA10123456784');
      expect(order.shippingDetails?.carrier, 'UPS');
      expect(order.shippingDetails?.trackingUrl,
          'https://www.ups.com/track?tracknum=1Z999AA10123456784');
      expect(order.shippingDetails?.estimatedDelivery, '2026-09-25');
      expect(order.shippedAt, DateTime(2026, 9, 21, 14));
      expect(order.shippedNotificationSentAt, DateTime(2026, 9, 21, 14));
    });

    test('leaves shippingAddress null when the order has no shipping address on file', () async {
      final firestore = FakeFirebaseFirestore();
      final ref = firestore.collection('orders').doc('cs_test_noaddr');
      await ref.set({
        'status': 'paid',
        'stripeSessionId': 'cs_test_noaddr',
        'stripePaymentIntentId': 'pi_test_noaddr',
        'customer': {'email': 'digital@example.com', 'name': 'Digital Buyer', 'phone': null},
        'items': [
          {'name': 'Gift Card', 'qty': 1, 'amountTotal': 25.0},
        ],
        'total': 25.0,
        'currency': 'usd',
        'shippingAddress': null,
        'notes': null,
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 20, 10)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 9, 20, 10)),
      });

      final snapshot = await ref.get();
      final order = Order.fromFirestore(snapshot);

      expect(order.shippingAddress, isNull);
    });
  });
}
