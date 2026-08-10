import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';

/// Screen for newsletter subscription management
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late TextEditingController _emailController;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Newsletter'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Consumer<SubscriptionProvider>(
          builder: (context, subscriptionProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Stay Updated',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Subscribe to our newsletter for exclusive updates, offers, and news',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),

                // Error message
                if (subscriptionProvider.hasError)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            subscriptionProvider.error ?? 'An error occurred',
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Success message
                if (subscriptionProvider.isSubscribed && !subscriptionProvider.hasError)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      border: Border.all(color: Colors.green[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Successfully subscribed! Check your email for confirmation.',
                            style: TextStyle(color: Colors.green[700]),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (subscriptionProvider.isSubscribed && !subscriptionProvider.hasError) ...[
                  const SizedBox(height: 24),
                  // Subscription details
                  if (subscriptionProvider.currentSubscription != null)
                    _SubscriptionDetails(
                      subscription: subscriptionProvider.currentSubscription!,
                    ),
                  const SizedBox(height: 24),
                  // Unsubscribe button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: subscriptionProvider.isLoading
                          ? null
                          : () async {
                              if (subscriptionProvider.currentSubscription?.id != null) {
                                await subscriptionProvider.cancelSubscription(
                                  subscriptionProvider.currentSubscription!.id!,
                                );
                              }
                            },
                      icon: const Icon(Icons.unsubscribe),
                      label: subscriptionProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Unsubscribe'),
                    ),
                  ),
                ] else ...[
                  // Email field
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address *',
                      hintText: 'your@email.com',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !subscriptionProvider.isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Name field
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name (Optional)',
                      hintText: 'Your Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    enabled: !subscriptionProvider.isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Subscribe button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: subscriptionProvider.isLoading
                          ? null
                          : () async {
                              final email = _emailController.text.trim();
                              final name = _nameController.text.trim();

                              if (email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter an email address'),
                                  ),
                                );
                                return;
                              }

                              final success = await subscriptionProvider.subscribe(
                                email: email,
                                name: name.isNotEmpty ? name : null,
                              );

                              if (success && mounted) {
                                // Clear form on success
                                _emailController.clear();
                                _nameController.clear();
                              }
                            },
                      icon: subscriptionProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.email),
                      label: Text(
                        subscriptionProvider.isLoading ? 'Subscribing...' : 'Subscribe',
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Widget to display subscription details
class _SubscriptionDetails extends StatelessWidget {
  final dynamic subscription;

  const _SubscriptionDetails({
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Email',
              value: subscription.email,
            ),
            if (subscription.name != null)
              _DetailRow(
                label: 'Name',
                value: subscription.name,
              ),
            if (subscription.status != null)
              _DetailRow(
                label: 'Status',
                value: subscription.status,
              ),
            if (subscription.subscriptionDate != null)
              _DetailRow(
                label: 'Subscribed',
                value: subscription.subscriptionDate.toString().split(' ')[0],
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper widget for subscription detail rows
class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Flexible(
            child: Text(
              value ?? 'N/A',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
