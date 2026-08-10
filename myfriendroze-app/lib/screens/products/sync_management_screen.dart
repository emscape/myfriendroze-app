import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/sync_status_indicator.dart';
import '../../services/astro_integration_service.dart';

class SyncManagementScreen extends StatefulWidget {
  const SyncManagementScreen({super.key});

  @override
  State<SyncManagementScreen> createState() => _SyncManagementScreenState();
}

class _SyncManagementScreenState extends State<SyncManagementScreen> {
  bool _isCheckingHealth = false;
  bool _astroHealthy = false;
  Map<String, dynamic>? _syncStats;

  @override
  void initState() {
    super.initState();
    _checkAstroHealth();
    _loadSyncStats();
  }

  Future<void> _checkAstroHealth() async {
    setState(() => _isCheckingHealth = true);
    try {
      final healthy = await AstroIntegrationManager.instance.checkIntegrationHealth();
      setState(() => _astroHealthy = healthy);
    } catch (e) {
      setState(() => _astroHealthy = false);
    } finally {
      setState(() => _isCheckingHealth = false);
    }
  }

  Future<void> _loadSyncStats() async {
    try {
      final stats = await AstroIntegrationManager.instance.getSyncStats();
      setState(() => _syncStats = stats);
    } catch (e) {
      // Stats are optional, don't show error
    }
  }

  Future<void> _triggerSiteRebuild() async {
    try {
      final success = await AstroIntegrationManager.instance.triggerSiteRebuild();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Site rebuild triggered successfully!' 
                : 'Failed to trigger site rebuild'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Astro Sync Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkAstroHealth();
              _loadSyncStats();
            },
            tooltip: 'Refresh status',
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Astro Health Status
                _buildHealthStatusCard(),
                const SizedBox(height: 16),

                // Sync Summary
                SyncStatusSummary(
                  products: productProvider.products,
                  onSyncAll: () => productProvider.syncAllProductsWithAstro(),
                  isLoading: productProvider.isLoading,
                ),
                const SizedBox(height: 16),

                // Sync Statistics
                if (_syncStats != null) _buildSyncStatsCard(),
                const SizedBox(height: 16),

                // Manual Actions
                _buildManualActionsCard(productProvider),
                const SizedBox(height: 16),

                // Product List with Sync Status
                _buildProductSyncList(productProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHealthStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _astroHealthy ? Icons.check_circle : Icons.error,
                  color: _astroHealthy ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Astro Integration Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_isCheckingHealth)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _astroHealthy 
                  ? 'Connected and ready to sync products'
                  : 'Unable to connect to Astro site. Check your configuration.',
              style: TextStyle(
                color: _astroHealthy 
                    ? Colors.green 
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (_syncStats != null) ...[
              _buildStatRow('Total Products', _syncStats!['totalProducts']?.toString() ?? '0'),
              _buildStatRow('Last Sync', _syncStats!['lastSync']?.toString() ?? 'Never'),
              _buildStatRow('Success Rate', '${_syncStats!['successRate']?.toString() ?? '0'}%'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildManualActionsCard(ProductProvider productProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manual Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: productProvider.isLoading 
                        ? null 
                        : () => productProvider.syncAllProductsWithAstro(),
                    icon: productProvider.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: const Text('Sync All Products'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _triggerSiteRebuild,
                    icon: const Icon(Icons.build),
                    label: const Text('Rebuild Site'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSyncList(ProductProvider productProvider) {
    final products = productProvider.products;
    
    if (products.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No products to sync'),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Product Sync Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: product.imageUrls.isNotEmpty
                      ? NetworkImage(product.imageUrls.first)
                      : null,
                  child: product.imageUrls.isEmpty
                      ? const Icon(Icons.image)
                      : null,
                ),
                title: Text(product.title),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SyncStatusIndicator(
                      status: product.syncStatus,
                      lastSyncAt: product.lastSyncAt,
                      error: product.syncError,
                      compact: true,
                      showText: false,
                    ),
                    IconButton(
                      icon: const Icon(Icons.sync),
                      onPressed: () => productProvider.syncProductWithAstro(product),
                      tooltip: 'Sync this product',
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
