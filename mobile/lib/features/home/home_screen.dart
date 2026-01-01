import 'package:flutter/material.dart';
import '../../core/config/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../features/bible_verse/verse_service.dart';
import '../../widgets/error_message.dart';
import '../../widgets/loading_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _error;
  bool _verseLoading = true;
  String? _verseError;
  Map<String, dynamic>? _verse;

  @override
  void initState() {
    super.initState();
    _loadVerse();
  }

  Future<void> _loadVerse() async {
    setState(() {
      _verseLoading = true;
      _verseError = null;
    });
    try {
      final data = await VerseService.fetchVerse();
      if (!mounted) return;
      setState(() => _verse = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _verseError = e.toString());
    } finally {
      if (mounted) setState(() => _verseLoading = false);
    }
  }

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
      _NavItem('Resources', AppRoutes.resources, Icons.folder_open),
      _NavItem('Member Resources', AppRoutes.memberResources, Icons.lock_outline, requiresAuth: true),
      _NavItem('Health Check', AppRoutes.health, Icons.favorite_outline),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('ChurchConnect')),
      body: RefreshIndicator(
        onRefresh: _loadVerse,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildVerseCard(context);
            }
            final item = items[index - 1];
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
    );
  }

  Widget _buildVerseCard(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceVariant;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Verse of the Day', style: TextStyle(fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _verseLoading ? null : _loadVerse,
                tooltip: 'Refresh verse',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_verseLoading)
            const LoadingIndicator(message: 'Loading verse...')
          else if (_verseError != null)
            ErrorMessage(message: _verseError!, onRetry: _loadVerse)
          else if (_verse == null)
            const Text('No verse available right now')
          else ...[
            Text(_verse?['ref']?.toString() ?? '', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(_verse?['text']?.toString() ?? ''),
          ],
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
