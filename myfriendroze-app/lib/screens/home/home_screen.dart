import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyFriendRoze Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome message
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Logged in as: ${authProvider.user?.email ?? 'Unknown'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Quick actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Action cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    context,
                    title: 'Products',
                    subtitle: 'Manage products',
                    icon: Icons.inventory,
                    onTap: () => context.go('/products'),
                  ),
                  _buildActionCard(
                    context,
                    title: 'Add Product',
                    subtitle: 'Create new product',
                    icon: Icons.add_box,
                    onTap: () => context.go('/products/add'),
                  ),
                  _buildActionCard(
                    context,
                    title: 'Events',
                    subtitle: 'Manage events',
                    icon: Icons.event,
                    onTap: () => context.go('/events'),
                  ),
                  _buildActionCard(
                    context,
                    title: 'Add Event',
                    subtitle: 'Create new event',
                    icon: Icons.event_note,
                    onTap: () => context.go('/events/add'),
                  ),
                  _buildActionCard(
                    context,
                    title: 'Gallery',
                    subtitle: 'Manage gallery photos',
                    icon: Icons.photo_library,
                    onTap: () => context.go('/gallery'),
                  ),
                  _buildActionCard(
                    context,
                    title: 'Add Gallery Photo',
                    subtitle: 'Upload a new photo',
                    icon: Icons.add_photo_alternate,
                    onTap: () => context.go('/gallery/add'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
