import 'package:flutter/material.dart';
import '../models/product.dart';

/// Widget to display sync status for products
class SyncStatusIndicator extends StatelessWidget {
  final ProductSyncStatus status;
  final DateTime? lastSyncAt;
  final String? error;
  final VoidCallback? onRetry;
  final bool showText;
  final bool compact;

  const SyncStatusIndicator({
    super.key,
    required this.status,
    this.lastSyncAt,
    this.error,
    this.onRetry,
    this.showText = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (compact) {
      return _buildCompactIndicator(theme);
    }
    
    return _buildFullIndicator(theme);
  }

  Widget _buildCompactIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(theme).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(theme).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIcon(theme, size: 12),
          if (showText) ...[
            const SizedBox(width: 4),
            Text(
              status.displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getStatusColor(theme),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullIndicator(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(theme),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Astro Sync: ${status.displayName}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _getStatusColor(theme),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (status == ProductSyncStatus.failed && onRetry != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRetry,
                    tooltip: 'Retry sync',
                    iconSize: 20,
                  ),
              ],
            ),
            if (lastSyncAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last sync: ${_formatDateTime(lastSyncAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
            if (error != null && status == ProductSyncStatus.failed) ...[
              const SizedBox(height: 4),
              Text(
                'Error: $error',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ThemeData theme, {double size = 16}) {
    switch (status) {
      case ProductSyncStatus.pending:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(_getStatusColor(theme)),
          ),
        );
      case ProductSyncStatus.synced:
        return Icon(
          Icons.check_circle,
          color: _getStatusColor(theme),
          size: size,
        );
      case ProductSyncStatus.failed:
        return Icon(
          Icons.error,
          color: _getStatusColor(theme),
          size: size,
        );
      case ProductSyncStatus.notSynced:
        return Icon(
          Icons.sync_disabled,
          color: _getStatusColor(theme),
          size: size,
        );
    }
  }

  Color _getStatusColor(ThemeData theme) {
    switch (status) {
      case ProductSyncStatus.pending:
        return theme.colorScheme.primary;
      case ProductSyncStatus.synced:
        return Colors.green;
      case ProductSyncStatus.failed:
        return theme.colorScheme.error;
      case ProductSyncStatus.notSynced:
        return theme.colorScheme.onSurface.withOpacity(0.5);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

/// Floating action button for sync operations
class SyncFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String tooltip;

  const SyncFloatingActionButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.tooltip = 'Sync with Astro',
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: isLoading ? null : onPressed,
      tooltip: tooltip,
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : const Icon(Icons.sync),
    );
  }
}

/// Sync status summary widget
class SyncStatusSummary extends StatelessWidget {
  final List<Product> products;
  final VoidCallback? onSyncAll;
  final bool isLoading;

  const SyncStatusSummary({
    super.key,
    required this.products,
    this.onSyncAll,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final syncedCount = products.where((p) => p.syncStatus == ProductSyncStatus.synced).length;
    final failedCount = products.where((p) => p.syncStatus == ProductSyncStatus.failed).length;
    final pendingCount = products.where((p) => p.syncStatus == ProductSyncStatus.pending).length;
    final notSyncedCount = products.where((p) => p.syncStatus == ProductSyncStatus.notSynced).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Astro Sync Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (onSyncAll != null)
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : onSyncAll,
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync, size: 16),
                    label: const Text('Sync All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip(theme, 'Synced', syncedCount, Colors.green),
                const SizedBox(width: 8),
                _buildStatusChip(theme, 'Failed', failedCount, theme.colorScheme.error),
                const SizedBox(width: 8),
                _buildStatusChip(theme, 'Pending', pendingCount, theme.colorScheme.primary),
                const SizedBox(width: 8),
                _buildStatusChip(theme, 'Not Synced', notSyncedCount, theme.colorScheme.onSurface.withOpacity(0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $count',
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
