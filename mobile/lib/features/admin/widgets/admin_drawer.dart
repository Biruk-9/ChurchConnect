import 'package:flutter/material.dart';
import '../../../core/config/app_routes.dart';
import '../../../core/services/auth_service.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard_rounded, 'route': AppRoutes.admin},
      {'title': 'Announcements', 'icon': Icons.campaign_rounded, 'route': AppRoutes.manageAnnouncements},
      {'title': 'Events', 'icon': Icons.event_rounded, 'route': AppRoutes.manageEvents},
      {'title': 'Resources', 'icon': Icons.folder_rounded, 'route': AppRoutes.manageResources},
      {'title': 'Members', 'icon': Icons.people_alt_rounded, 'route': AppRoutes.manageUsers},
      {'title': 'Verses', 'icon': Icons.menu_book_rounded, 'route': AppRoutes.manageVerses},
    ];

    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      backgroundColor: Colors.white.withOpacity(0.97),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: const [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.shield_rounded, color: Colors.white, size: 36),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: menuItems.map((item) {
                final isCurrent = currentRoute == item['route'];
                return ListTile(
                  leading: Icon(
                    item['icon'] as IconData,
                    color: isCurrent ? const Color(0xFF7C3AED) : null,
                  ),
                  title: Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                      color: isCurrent ? const Color(0xFF7C3AED) : null,
                    ),
                  ),
                  selected: isCurrent,
                  selectedTileColor: const Color(0xFF7C3AED).withOpacity(0.12),
                  onTap: () {
                    Navigator.pop(context);
                    if (!isCurrent) {
                      Navigator.pushNamed(context, item['route'] as String);
                    }
                  },
                );
              }).toList(),
            ),
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
