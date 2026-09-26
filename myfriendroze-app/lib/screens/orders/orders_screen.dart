import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'To Ship'),
              Tab(text: 'Shipped'),
            ],
          ),
        ),
        body: Consumer<OrderProvider>(
          builder: (context, orderProvider, _) {
            if (orderProvider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      orderProvider.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => orderProvider.loadOrders(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return TabBarView(
              children: [
                _OrderList(
                  orders: orderProvider.ordersNeedingShipping,
                  emptyMessage: 'No orders need shipping right now',
                  showDaysWaiting: true,
                ),
                _OrderList(
                  orders: orderProvider.shippedOrders,
                  emptyMessage: 'No shipped orders yet',
                  showDaysWaiting: false,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final String emptyMessage;
  final bool showDaysWaiting;

  const _OrderList({
    required this.orders,
    required this.emptyMessage,
    required this.showDaysWaiting,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(emptyMessage, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(order: order, showDaysWaiting: showDaysWaiting);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool showDaysWaiting;

  const _OrderCard({required this.order, required this.showDaysWaiting});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(name: order.currency.toUpperCase());
    final itemCount = order.items.fold<int>(0, (sum, item) => sum + item.qty);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () => context.go('/orders/detail', extra: order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.customer.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    currencyFormat.format(order.total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$itemCount item${itemCount != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                showDaysWaiting
                    ? 'Ordered ${_daysAgo(order.createdAt)}'
                    : 'Shipped ${order.shippedAt != null ? _daysAgo(order.shippedAt!) : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _daysAgo(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }
}
