import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  // Injectable so tests can supply a throwing/resolving loader directly,
  // instead of swapping PackageInfoPlatform.instance and depending on
  // PackageInfo.fromPlatform()'s undocumented global memoization (which
  // also made a test's outcome depend on run order — fragile under
  // `flutter test --test-randomize-ordering-seed`). Defaults to the real
  // platform lookup in production.
  final Future<PackageInfo> Function() packageInfoLoader;

  ProfileScreen({super.key, Future<PackageInfo> Function()? packageInfoLoader})
      : packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Was a hardcoded 'Version: 1.0.0' string — never reflected real
  // releases no matter how many shipped. buildNumber is set from the git
  // commit count at build time (see CLAUDE.md's Deployment section), so
  // it visibly changes on every real deploy — useful for confirming a
  // device/browser is actually running the build you think it is.
  String _versionLabel = '';

  @override
  void initState() {
    super.initState();
    widget.packageInfoLoader().then((info) {
      if (!mounted) return;
      setState(() {
        _versionLabel = 'Version ${info.version} (${info.buildNumber})';
      });
    }).catchError((Object error) {
      // A platform-channel/plugin-init failure here shouldn't take the
      // whole screen down (or fail silently forever) — surface a safe,
      // static fallback instead of leaving _versionLabel blank.
      if (!mounted) return;
      setState(() {
        _versionLabel = 'Version unavailable';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Color(0xFF2E7D32),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          authProvider.user?.email ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Admin User',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // App info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'App Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(_versionLabel),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(Icons.business, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('MyFriendRoze Admin'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Sign out button
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await _showSignOutConfirmation(context);
                    if (confirmed) {
                      await authProvider.signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool> _showSignOutConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    ) ?? false;
  }
}
