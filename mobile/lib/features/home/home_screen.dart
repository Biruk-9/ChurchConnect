import 'package:flutter/material.dart';
import '../../core/config/app_routes.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../features/bible_verse/verse_service.dart';
import '../../features/announcements/announcement_service.dart';
import '../../features/events/events_service.dart';
import '../../features/resources/resource_service.dart';
import '../../features/announcements/announcement_model.dart';
import '../../widgets/error_message.dart';
import '../../widgets/loading_indicator.dart';
import '../bible_verse/verse_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _verseLoading = true;
  String? _verseError;
  Verse? _verse;
  String? _userName;
  bool _isLoggedIn = false;
  bool _highlightsLoading = true;
  Announcement? _latestAnnouncement;
  Map<String, dynamic>? _latestEvent;
  Map<String, dynamic>? _latestResource;
  int _logoTapCount = 0;
  DateTime? _lastLogoTap;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadVerse();
    _loadHighlights();
  }

  Future<void> _loadUser() async {
    try {
      final loggedIn = await AuthService.isLoggedIn();
      final name = await AuthService.getUserName();
      if (!mounted) return;
      setState(() {
        _isLoggedIn = loggedIn;
        _userName = name;
      });
    } catch (_) {}
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
      final message = e is ApiException ? e.message : e.toString();
      setState(() => _verseError = message);
    } finally {
      if (mounted) setState(() => _verseLoading = false);
    }
  }

  Future<void> _loadHighlights() async {
    setState(() => _highlightsLoading = true);
    try {
      final announcements = await AnnouncementService.fetchPublic();
      final events = await EventsService.fetchAll();
      final resources = await ResourceService.fetchPublic();
      if (!mounted) return;
      setState(() {
        _latestAnnouncement = announcements.isNotEmpty ? announcements.first : null;
        final split = _splitEvents(events);
        _latestEvent = split.$1.isNotEmpty ? split.$1.first : null;
        _latestResource = resources.isNotEmpty ? resources.first : null;
      });
    } catch (_) {}
    finally {
      if (mounted) setState(() => _highlightsLoading = false);
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadUser(),
      _loadVerse(),
      _loadHighlights(),
    ]);
  }

  void _handleLogoTap() {
    final now = DateTime.now();
    if (_lastLogoTap == null || now.difference(_lastLogoTap!) > const Duration(seconds: 3)) {
      _logoTapCount = 0; // reset if too slow between taps
    }
    _lastLogoTap = now;
    _logoTapCount++;

    if (_logoTapCount >= 6) {
      _logoTapCount = 0;
      _lastLogoTap = null;
      Navigator.of(context).pushNamed(AppRoutes.admin);
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
      }
      if (!mounted) return;
      Navigator.of(context).pushNamed(route);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem('Announcements', AppRoutes.announcements, Icons.campaign_rounded, subtitle: 'News & updates'),
      _NavItem('Events', AppRoutes.events, Icons.event_rounded, subtitle: 'Upcoming gatherings'),
      _NavItem('Resources', AppRoutes.resources, Icons.menu_book_rounded, subtitle: 'Learn and grow'),
      _NavItem('Member Resources', AppRoutes.memberResources, Icons.lock_rounded, requiresAuth: true, subtitle: 'For members'),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Home',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
      ),
      drawer: _buildDrawer(items),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFFF8FAFC)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshAll,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeAndVerse(),
                  const SizedBox(height: 32),
                  _buildHighlightsSection(),
                  const SizedBox(height: 32),
                  _buildNavigationGrid(items),
                  const SizedBox(height: 40),
                  _buildContactFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeAndVerse() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleLogoTap,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.church_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName != null ? 'Hello, ${_userName!.split(' ').first}!' : 'Welcome Home',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Verse of the Day - Glassmorphic Card
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF312E81).withOpacity(0.92),
                const Color(0xFF6D28D9).withOpacity(0.88),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.24)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 32, offset: const Offset(0, 18)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Verse of the Day",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.1,
                      decoration: TextDecoration.underline,
                      decorationThickness: 1.5,
                      decorationColor: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                    onPressed: _verseLoading ? null : _loadVerse,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_verseLoading)
                const LoadingIndicator(message: 'Loading verse...')
              else if (_verseError != null)
                ErrorMessage(message: _verseError!)
              else if (_verse != null) ...[
                Text.rich(
                  TextSpan(
                    text: '"',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      height: 1.55,
                      letterSpacing: 0.2,
                    ),
                    children: [
                      TextSpan(
                        text: _verse!.text,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const TextSpan(text: '"'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _verse!.ref,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: Colors.white.withOpacity(0.9),
                    shadows: [
                      Shadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                ),
              ] else
                const Text(
                  'No verse available today',
                  style: TextStyle(color: Colors.white70),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Latest Highlights',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        if (_highlightsLoading)
          const LoadingIndicator(message: 'Loading highlights...')
        else
          Column(
            children: [
              _buildHighlightCard(
                title: 'Latest Announcement',
                content: _latestAnnouncement?.title ?? 'No announcements yet',
                icon: Icons.campaign_rounded,
                color: const Color(0xFF7C3AED),
                onTap: () => _go(context, AppRoutes.announcements),
              ),
              const SizedBox(height: 12),
              _buildHighlightCard(
                title: 'Next Event',
                content: _latestEvent != null ? _latestEvent!['title']?.toString() ?? 'Upcoming event' : 'No events scheduled',
                icon: Icons.event_rounded,
                color: const Color(0xFF2563EB),
                onTap: () => _go(context, AppRoutes.events),
              ),
              const SizedBox(height: 12),
              _buildHighlightCard(
                title: 'New Resource',
                content: _latestResource != null ? _latestResource!['title']?.toString() ?? 'Fresh resource' : 'No new resources',
                icon: Icons.folder_rounded,
                color: const Color(0xFF10B981),
                onTap: () => _go(context, AppRoutes.resources),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildHighlightCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationGrid(List<_NavItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.35,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return GestureDetector(
              onTap: () => _go(context, item.route, requiresAuth: item.requiresAuth),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContactFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stay Connected',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 14),
          _buildContactRow(Icons.phone_rounded, '+251 911 12 86 26', const Color(0xFF2563EB)),
          const SizedBox(height: 12),
          _buildContactRow(Icons.email_rounded, 'support@churchconnect.org', const Color(0xFF7C3AED)),
          const SizedBox(height: 12),
          _buildContactRow(Icons.location_on_rounded, 'Fresnsay, Mazoria', const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Drawer _buildDrawer(List<_NavItem> items) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.church_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName ?? 'Welcome',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _isLoggedIn ? 'Member' : 'Guest',
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: items.map((item) {
                return ListTile(
                  leading: Icon(item.icon, color: const Color(0xFF7C3AED)),
                  title: Text(item.title),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(context);
                    _go(context, item.route, requiresAuth: item.requiresAuth);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  (List<Map<String, dynamic>>, List<Map<String, dynamic>>) _splitEvents(List<Map<String, dynamic>> items) {
    final now = DateTime.now();
    final upcoming = <Map<String, dynamic>>[];
    final past = <Map<String, dynamic>>[];
    for (final item in items) {
      final date = _parseDate(item);
      if (date != null && date.isBefore(now)) {
        past.add(item);
      } else {
        upcoming.add(item);
      }
    }
    upcoming.sort((a, b) => (_parseDate(a) ?? now).compareTo(_parseDate(b) ?? now));
    past.sort((a, b) => (_parseDate(b) ?? now).compareTo(_parseDate(a) ?? now));
    return (upcoming, past);
  }

  DateTime? _parseDate(Map<String, dynamic> item) {
    final raw = item['startDate']?.toString() ?? item['date']?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class _NavItem {
  final String title;
  final String route;
  final IconData icon;
  final bool requiresAuth;
  final String? subtitle;

  _NavItem(this.title, this.route, this.icon, {this.requiresAuth = false, this.subtitle});
}