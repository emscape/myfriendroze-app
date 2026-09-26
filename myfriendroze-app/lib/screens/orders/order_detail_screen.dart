import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../utils/tracking_url.dart';
import '../../widgets/custom_text_field.dart';

const List<String> _knownCarriers = ['USPS', 'UPS', 'FedEx', 'DHL', 'Other'];

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _trackingNumberController = TextEditingController();
  final _trackingUrlController = TextEditingController();
  final _estimatedDeliveryController = TextEditingController();
  final _otherCarrierController = TextEditingController();
  String _selectedCarrier = _knownCarriers.first;
  bool _trackingUrlManuallyEdited = false;

  @override
  void dispose() {
    _trackingNumberController.dispose();
    _trackingUrlController.dispose();
    _estimatedDeliveryController.dispose();
    _otherCarrierController.dispose();
    super.dispose();
  }

  String get _effectiveCarrier =>
      _selectedCarrier == 'Other' ? _otherCarrierController.text.trim() : _selectedCarrier;

  void _autoFillTrackingUrl() {
    if (_trackingUrlManuallyEdited) return;
    final url = buildTrackingUrl(_effectiveCarrier, _trackingNumberController.text);
    // Explicitly clears to '' rather than leaving a stale value when the
    // carrier has no known URL pattern (e.g. switched to "Other") -- an
    // auto-filled URL for the PREVIOUS carrier would otherwise still get
    // submitted alongside the new one.
    _trackingUrlController.text = url ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<OrderProvider>();
    final success = await provider.markShipped(
      widget.order.id,
      trackingNumber: _trackingNumberController.text.trim(),
      carrier: _effectiveCarrier,
      trackingUrl: _trackingUrlController.text.trim().isEmpty
          ? null
          : _trackingUrlController.text.trim(),
      estimatedDelivery: _estimatedDeliveryController.text.trim().isEmpty
          ? null
          : _estimatedDeliveryController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order marked as shipped')),
      );
      context.go('/orders');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to mark order shipped')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final currencyFormat = NumberFormat.simpleCurrency(name: order.currency.toUpperCase());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/orders'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Customer',
            children: [
              Text(order.customer.name),
              Text(order.customer.email, style: TextStyle(color: Colors.grey[600])),
              if (order.customer.phone != null && order.customer.phone!.isNotEmpty)
                Text(order.customer.phone!, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Items',
            children: [
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${item.name} x${item.qty}')),
                      Text(currencyFormat.format(item.amountTotal)),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    currencyFormat.format(order.total),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Shipping Address',
            children: [
              if (order.shippingAddress != null) ...[
                Text(order.shippingAddress!.name),
                Text(order.shippingAddress!.line1),
                if (order.shippingAddress!.line2 != null &&
                    order.shippingAddress!.line2!.isNotEmpty)
                  Text(order.shippingAddress!.line2!),
                Text(
                  '${order.shippingAddress!.city}, ${order.shippingAddress!.state} '
                  '${order.shippingAddress!.postalCode}',
                ),
                Text(order.shippingAddress!.country),
              ] else
                Text('No shipping address on file', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(title: 'Notes', children: [Text(order.notes!)]),
          ],
          const SizedBox(height: 12),
          if (order.status == 'shipped')
            _SectionCard(
              title: 'Shipping Details',
              children: [
                Text('Carrier: ${order.shippingDetails?.carrier ?? '-'}'),
                Text('Tracking #: ${order.shippingDetails?.trackingNumber ?? '-'}'),
                if (order.shippingDetails?.trackingUrl != null)
                  Text(
                    order.shippingDetails!.trackingUrl!,
                    style: const TextStyle(color: Colors.blue),
                  ),
                if (order.shippingDetails?.estimatedDelivery != null)
                  Text('Estimated delivery: ${order.shippingDetails!.estimatedDelivery}'),
              ],
            )
          else
            _SectionCard(
              title: 'Mark as Shipped',
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedCarrier,
                        decoration: const InputDecoration(labelText: 'Carrier'),
                        items: _knownCarriers
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCarrier = value ?? _knownCarriers.first;
                            _autoFillTrackingUrl();
                          });
                        },
                      ),
                      if (_selectedCarrier == 'Other') ...[
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _otherCarrierController,
                          labelText: 'Carrier Name',
                          validator: (value) =>
                              (value == null || value.trim().isEmpty) ? 'Required' : null,
                        ),
                      ],
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _trackingNumberController,
                        labelText: 'Tracking Number',
                        onChanged: (_) => setState(_autoFillTrackingUrl),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _trackingUrlController,
                        labelText: 'Tracking URL (optional)',
                        onChanged: (_) => _trackingUrlManuallyEdited = true,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _estimatedDeliveryController,
                        labelText: 'Estimated Delivery (optional)',
                      ),
                      const SizedBox(height: 16),
                      Consumer<OrderProvider>(
                        builder: (context, provider, _) => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: provider.isLoading ? null : _submit,
                            child: provider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Mark Shipped'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
