import 'package:flutter/material.dart';
import '../../core/config/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/error_message.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _error;

  Future<void> _go(BuildContext context, String route, {bool requiresAuth = false}) async {
    if (!requiresAuth) {
      Navigator.of(context).pushNamed(route);
      return;
    }

    try {
      final loggedIn = await AuthService.isLoggedIn();
      if (!loggedIn) {
        if (!mounted) return;
        await Navigator.of(context).pushNamed(AppRoutes.login);
      } else {
        if (!mounted) return;
        Navigator.of(context).pushNamed(route);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem('Announcements', AppRoutes.announcements, Icons.campaign_outlined),
      _NavItem('Events', AppRoutes.events, Icons.event_outlined),
      _NavItem('Bible Verse of the Day', AppRoutes.verse, Icons.menu_book_outlined),
      _NavItem('Resources', AppRoutes.resources, Icons.folder_open),
      _NavItem('Member Resources', AppRoutes.memberResources, Icons.lock_outline, requiresAuth: true),
      _NavItem('Health Check', AppRoutes.health, Icons.favorite_outline),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('ChurchConnect')),
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ErrorMessage(message: _error!),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  tileColor: Theme.of(context).colorScheme.surfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: Icon(item.icon),
                  title: Text(item.title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _go(context, item.route, requiresAuth: item.requiresAuth),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String title;
  final String route;
  final IconData icon;
  final bool requiresAuth;
  _NavItem(this.title, this.route, this.icon, {this.requiresAuth = false});
}
