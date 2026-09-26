import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myfriendroze_admin/models/order.dart';
import 'package:myfriendroze_admin/providers/order_provider.dart';
import 'package:myfriendroze_admin/screens/orders/orders_screen.dart';
import 'package:myfriendroze_admin/services/order_shipping_service.dart';

class _NoopShippingService implements OrderShippingService {
  @override
  Future<Map<String, dynamic>> markShipped({
    required String orderId,
    required Map<String, dynamic> shippingDetails,
  }) async {
    return {'success': true};
  }
}

Order buildOrder({
  required String id,
  required String status,
  String customerName = 'Jane Buyer',
  double total = 20.0,
}) {
  final now = DateTime(2026, 9, 20);
  return Order(
    id: id,
    status: status,
    stripeSessionId: id,
    stripePaymentIntentId: 'pi_$id',
    customer: Customer(email: '$id@example.com', name: customerName),
    items: [OrderItem(name: 'Mug', qty: 1, amountTotal: total)],
    total: total,
    currency: 'usd',
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeOrderProvider extends OrderProvider {
  final List<Order> fakeOrders;
  final bool fakeIsLoadingOrders;

  _FakeOrderProvider(this.fakeOrders, {this.fakeIsLoadingOrders = false})
      : super(shippingService: _NoopShippingService());

  @override
  List<Order> get ordersNeedingShipping =>
      fakeOrders.where((o) => o.status == 'paid').toList();

  @override
  List<Order> get shippedOrders =>
      fakeOrders.where((o) => o.status == 'shipped').toList();

  @override
  bool get isLoadingOrders => fakeIsLoadingOrders;

  @override
  void loadOrders() {
    // No-op: this test injects orders directly rather than through Firestore.
  }
}

void main() {
  testWidgets('shows paid orders in "To Ship" and shipped orders in "Shipped"', (tester) async {
    final provider = _FakeOrderProvider([
      buildOrder(id: 'cs_paid', status: 'paid', customerName: 'Paid Customer'),
      buildOrder(id: 'cs_shipped', status: 'shipped', customerName: 'Shipped Customer'),
    ]);

    await tester.pumpWidget(
      ChangeNotifierProvider<OrderProvider>.value(
        value: provider,
        child: const MaterialApp(home: OrdersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paid Customer'), findsOneWidget);
    expect(find.text('Shipped Customer'), findsNothing);

    await tester.tap(find.text('Shipped'));
    await tester.pumpAndSettle();

    expect(find.text('Shipped Customer'), findsOneWidget);
    expect(find.text('Paid Customer'), findsNothing);
  });

  testWidgets('shows an empty state when there are no orders needing shipping', (tester) async {
    final provider = _FakeOrderProvider([]);

    await tester.pumpWidget(
      ChangeNotifierProvider<OrderProvider>.value(
        value: provider,
        child: const MaterialApp(home: OrdersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No orders'), findsOneWidget);
  });

  testWidgets('shows a loading indicator instead of the empty state before the first snapshot arrives',
      (tester) async {
    final provider = _FakeOrderProvider([], fakeIsLoadingOrders: true);

    await tester.pumpWidget(
      ChangeNotifierProvider<OrderProvider>.value(
        value: provider,
        child: const MaterialApp(home: OrdersScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('No orders'), findsNothing);
  });

  testWidgets('a long customer name does not overflow the order card', (tester) async {
    final provider = _FakeOrderProvider([
      buildOrder(
        id: 'cs_long',
        status: 'paid',
        customerName: 'Alexandria Montgomery-Fitzgerald the Third of Wonderland',
      ),
    ]);

    await tester.pumpWidget(
      ChangeNotifierProvider<OrderProvider>.value(
        value: provider,
        child: const MaterialApp(home: OrdersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
