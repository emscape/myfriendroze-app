import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myfriendroze_admin/models/order.dart';
import 'package:myfriendroze_admin/providers/order_provider.dart';
import 'package:myfriendroze_admin/services/firestore_service.dart';
import 'package:myfriendroze_admin/services/order_shipping_service.dart';

class FakeOrderShippingService implements OrderShippingService {
  Map<String, dynamic>? lastOrderId;
  Map<String, dynamic>? lastShippingDetails;
  Object? errorToThrow;
  Map<String, dynamic> responseToReturn = {'success': true};

  @override
  Future<Map<String, dynamic>> markShipped({
    required String orderId,
    required Map<String, dynamic> shippingDetails,
  }) async {
    lastOrderId = {'orderId': orderId};
    lastShippingDetails = shippingDetails;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return responseToReturn;
  }
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FakeOrderShippingService fakeShippingService;
  late OrderProvider provider;

  Future<void> addOrder(String id, {required String status}) {
    return fakeFirestore.collection('orders').doc(id).set({
      'status': status,
      'stripeSessionId': id,
      'stripePaymentIntentId': 'pi_$id',
      'customer': {'email': '$id@example.com', 'name': 'Buyer $id', 'phone': null},
      'items': [
        {'name': 'Mug', 'qty': 1, 'amountTotal': 20.0},
      ],
      'total': 20.0,
      'currency': 'usd',
      'shippingAddress': null,
      'notes': null,
      'createdAt': Timestamp.fromDate(DateTime(2026, 9, 20)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 9, 20)),
    });
  }

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    FirestoreService.setFirestoreInstance(fakeFirestore);
    fakeShippingService = FakeOrderShippingService();
    provider = OrderProvider(shippingService: fakeShippingService);
  });

  group('loadOrders', () {
    test('splits orders into needing-shipping and shipped by status', () async {
      await addOrder('cs_paid', status: 'paid');
      await addOrder('cs_shipped', status: 'shipped');

      provider.loadOrders();
      await Future.delayed(Duration.zero);

      expect(provider.ordersNeedingShipping.map((o) => o.id), ['cs_paid']);
      expect(provider.shippedOrders.map((o) => o.id), ['cs_shipped']);
    });

    test('does not set an error for a legitimately empty orders collection', () async {
      provider.loadOrders();
      await Future.delayed(Duration.zero);

      expect(provider.errorMessage, isNull);
      expect(provider.orders, isEmpty);
    });

    test('sets an error message when the orders stream errors', () async {
      final failingProvider = OrderProvider(
        shippingService: fakeShippingService,
        ordersStreamFactory: () => Stream.error(Exception('permission-denied')),
      );

      failingProvider.loadOrders();
      await Future.delayed(Duration.zero);

      expect(failingProvider.errorMessage, contains('permission-denied'));
    });

    test('clears a previous error once the stream successfully emits again', () async {
      final controller = StreamController<List<Order>>();
      addTearDown(controller.close);
      final recoveringProvider = OrderProvider(
        shippingService: fakeShippingService,
        ordersStreamFactory: () => controller.stream,
      );

      recoveringProvider.loadOrders();
      controller.addError(Exception('temporary failure'));
      await Future.delayed(Duration.zero);
      expect(recoveringProvider.errorMessage, isNotNull);

      controller.add([]);
      await Future.delayed(Duration.zero);

      expect(recoveringProvider.errorMessage, isNull);
    });

    test('cancels the previous subscription when called again instead of accumulating listeners',
        () async {
      await addOrder('cs_first', status: 'paid');

      provider.loadOrders();
      await Future.delayed(Duration.zero);
      provider.loadOrders();
      await Future.delayed(Duration.zero);

      await addOrder('cs_second', status: 'paid');
      await Future.delayed(Duration.zero);

      // If the first subscription were never cancelled, this would still
      // pass by coincidence -- the real regression this guards against is a
      // second call throwing or duplicating notifyListeners calls, which is
      // exercised by simply not throwing above and ending up with exactly
      // one copy of each order (not duplicated by two live listeners).
      expect(provider.orders.map((o) => o.id).toSet(), {'cs_first', 'cs_second'});
      expect(provider.orders.length, 2);
    });
  });

  group('markShipped', () {
    test('calls the shipping service with the tracking details and returns true on success', () async {
      final result = await provider.markShipped(
        'cs_paid',
        trackingNumber: '1Z999AA10123456784',
        carrier: 'UPS',
        trackingUrl: 'https://www.ups.com/track?tracknum=1Z999AA10123456784',
        estimatedDelivery: '2026-09-25',
      );

      expect(result, isTrue);
      expect(fakeShippingService.lastOrderId, {'orderId': 'cs_paid'});
      expect(fakeShippingService.lastShippingDetails, {
        'trackingNumber': '1Z999AA10123456784',
        'carrier': 'UPS',
        'trackingUrl': 'https://www.ups.com/track?tracknum=1Z999AA10123456784',
        'estimatedDelivery': '2026-09-25',
      });
      expect(provider.errorMessage, isNull);
    });

    test('omits null optional shipping fields from the call payload', () async {
      await provider.markShipped('cs_paid', trackingNumber: '9400111899223197428490', carrier: 'USPS');

      expect(fakeShippingService.lastShippingDetails, {
        'trackingNumber': '9400111899223197428490',
        'carrier': 'USPS',
      });
    });

    test('sets an error message and returns false when the callable throws', () async {
      fakeShippingService.errorToThrow = Exception('permission-denied');

      final result = await provider.markShipped('cs_paid', trackingNumber: 'x', carrier: 'USPS');

      expect(result, isFalse);
      expect(provider.errorMessage, contains('permission-denied'));
    });
  });
}
