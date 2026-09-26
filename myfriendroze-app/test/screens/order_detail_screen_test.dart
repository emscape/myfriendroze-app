import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:myfriendroze_admin/models/order.dart';
import 'package:myfriendroze_admin/providers/order_provider.dart';
import 'package:myfriendroze_admin/screens/orders/order_detail_screen.dart';
import 'package:myfriendroze_admin/services/order_shipping_service.dart';

class FakeOrderShippingService implements OrderShippingService {
  String? lastOrderId;
  Map<String, dynamic>? lastShippingDetails;
  Object? errorToThrow;

  @override
  Future<Map<String, dynamic>> markShipped({
    required String orderId,
    required Map<String, dynamic> shippingDetails,
  }) async {
    lastOrderId = orderId;
    lastShippingDetails = shippingDetails;
    if (errorToThrow != null) throw errorToThrow!;
    return {'success': true};
  }
}

Order buildOrder({required String status, ShippingDetails? shippingDetails}) {
  final now = DateTime(2026, 9, 20);
  return Order(
    id: 'cs_test123',
    status: status,
    stripeSessionId: 'cs_test123',
    stripePaymentIntentId: 'pi_test123',
    customer: Customer(email: 'buyer@example.com', name: 'Jane Buyer', phone: '555-0100'),
    items: [
      OrderItem(name: 'Mug', qty: 2, amountTotal: 36.0),
      OrderItem(name: 'Bowl', qty: 1, amountTotal: 28.0),
    ],
    total: 64.0,
    currency: 'usd',
    shippingAddress: ShippingAddress(
      name: 'Jane Buyer',
      line1: '123 Main St',
      city: 'Long Beach',
      state: 'CA',
      postalCode: '90802',
      country: 'US',
    ),
    createdAt: now,
    updatedAt: now,
    shippingDetails: shippingDetails,
    shippedAt: shippingDetails != null ? now : null,
  );
}

Widget wrap(Widget child, OrderProvider provider) {
  return ChangeNotifierProvider<OrderProvider>.value(
    value: provider,
    child: MaterialApp(home: child),
  );
}

// Unlike `wrap`, gives the widget a real GoRouter ancestor -- needed only by
// the success path below, which navigates back to '/orders' via context.go.
Widget wrapWithRouter(Widget child, OrderProvider provider) {
  final router = GoRouter(
    initialLocation: '/detail',
    routes: [
      GoRoute(path: '/detail', builder: (context, state) => child),
      GoRoute(path: '/orders', builder: (context, state) => const Scaffold()),
    ],
  );
  return ChangeNotifierProvider<OrderProvider>.value(
    value: provider,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('a paid order shows the mark-shipped form, not shipping details', (tester) async {
    final order = buildOrder(status: 'paid');
    final provider = OrderProvider(shippingService: FakeOrderShippingService());

    await tester.pumpWidget(wrap(OrderDetailScreen(order: order), provider));
    await tester.pumpAndSettle();

    expect(find.text('Jane Buyer'), findsWidgets);
    expect(find.textContaining('Long Beach'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Mark Shipped'), findsOneWidget);
    expect(find.text('Tracking Number'), findsOneWidget);
  });

  testWidgets('a shipped order shows read-only shipping details, not the form', (tester) async {
    final order = buildOrder(
      status: 'shipped',
      shippingDetails: ShippingDetails(
        trackingNumber: '1Z999AA10123456784',
        carrier: 'UPS',
        trackingUrl: 'https://www.ups.com/track?tracknum=1Z999AA10123456784',
      ),
    );
    final provider = OrderProvider(shippingService: FakeOrderShippingService());

    await tester.pumpWidget(wrap(OrderDetailScreen(order: order), provider));
    await tester.pumpAndSettle();

    // Appears twice: once in "Tracking #: ..." and once in the trackingUrl text.
    expect(find.textContaining('1Z999AA10123456784'), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Mark Shipped'), findsNothing);
  });

  testWidgets('submitting the mark-shipped form calls the provider with entered tracking details',
      (tester) async {
    // Taller surface so the whole (long) form is on-screen at once -- avoids
    // scrolling the DropdownButtonFormField and submit button into view one
    // at a time, which is brittle with ensureVisible on a ListView this long.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final order = buildOrder(status: 'paid');
    final fakeService = FakeOrderShippingService();
    final provider = OrderProvider(shippingService: fakeService);

    await tester.pumpWidget(wrapWithRouter(OrderDetailScreen(order: order), provider));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Tracking Number'), '1Z999AA10123456784');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('UPS').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Mark Shipped'));
    await tester.pumpAndSettle();

    expect(fakeService.lastOrderId, 'cs_test123');
    expect(fakeService.lastShippingDetails?['trackingNumber'], '1Z999AA10123456784');
    expect(fakeService.lastShippingDetails?['carrier'], 'UPS');
  });
}
