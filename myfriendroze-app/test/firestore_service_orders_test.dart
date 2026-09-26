import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:myfriendroze_admin/services/firestore_service.dart';

void main() {
  group('FirestoreService.getOrders', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      FirestoreService.setFirestoreInstance(fakeFirestore);
    });

    Future<void> addOrder(String id, {required String status, required DateTime createdAt}) {
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
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(createdAt),
      });
    }

    test('emits orders newest-first by createdAt', () async {
      await addOrder('cs_older', status: 'paid', createdAt: DateTime(2026, 9, 18));
      await addOrder('cs_newer', status: 'paid', createdAt: DateTime(2026, 9, 20));

      final orders = await FirestoreService.getOrders().first;

      expect(orders.map((o) => o.id).toList(), ['cs_newer', 'cs_older']);
    });

    test('includes both paid and shipped orders in a single stream', () async {
      await addOrder('cs_paid', status: 'paid', createdAt: DateTime(2026, 9, 20));
      await addOrder('cs_shipped', status: 'shipped', createdAt: DateTime(2026, 9, 19));

      final orders = await FirestoreService.getOrders().first;

      expect(orders.map((o) => o.status).toSet(), {'paid', 'shipped'});
    });
  });
}
