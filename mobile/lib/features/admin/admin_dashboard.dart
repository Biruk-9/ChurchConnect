import 'package:flutter/material.dart';
import '../../core/config/app_routes.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'widgets/admin_drawer.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _checking = true;
  bool _authed = false;
  bool _isAdmin = false;
  bool _loadingData = false;

  String? _adminName;
  String? _lastLogin;

  Map<String, dynamic>? _summary;
  String? _error;
  String? _dashboardError;

  @override
  void initState() {
    super.initState();
    _ensureAuth();
  }

  Future<void> _ensureAuth() async {
    try {
      final loggedIn = await AuthService.isLoggedIn();
      if (!loggedIn) {
        if (!mounted) return;
        await Navigator.of(context).pushNamed(AppRoutes.login);
        final afterLogin = await AuthService.isLoggedIn();
        final role = await AuthService.getRole();
        final name = await AuthService.getUserName();

        setState(() {
          _authed = afterLogin;
          _isAdmin = role == 'admin';
          _adminName = name ?? 'Admin';
          _checking = false;
        });

        if (afterLogin && role == 'admin') {
          await _loadDashboard();
        }
      } else {
        final role = await AuthService.getRole();
        final name = await AuthService.getUserName();

        setState(() {
          _authed = true;
          _isAdmin = role == 'admin';
          _adminName = name ?? 'Admin';
          _checking = false;
        });

        if (role == 'admin') {
          await _loadDashboard();
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _checking = false;
      });
    }
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loadingData = true;
      _dashboardError = null;
    });

    try {
      final summary = await AdminService.fetchSummary();

      if (!mounted) return;

      setState(() {
        _summary = summary;
        _loadingData = false;
        _lastLogin = "Today"; // ← placeholder - improve later if needed
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dashboardError = e.toString();
        _loadingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: LoadingIndicator(message: 'Checking access...'));
    }

    if (_error != null) {
      return Scaffold(body: Center(child: ErrorMessage(message: _error!)));
    }

    if (!_authed || !_isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Admin access required', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  await AuthService.logout();
                  if (!mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
                },
                child: const Text('Login as Admin'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      drawer: const AdminDrawer(),

      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFEEF2FF),
              child: Text(
                _adminName?.substring(0, 1).toUpperCase() ?? 'A',
                style: const TextStyle(color: Color(0xFF4C1D95)),
              ),
            ),
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFFF8FAFC),
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${_adminName ?? "Admin"}!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lastLogin != null ? 'Last active: $_lastLogin' : '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (_loadingData)
                    const LoadingIndicator(message: 'Loading dashboard...')
                  else if (_dashboardError != null)
                    ErrorMessage(message: _dashboardError!)
                  else
                    _buildStatsGrid(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final summary = _summary ?? {};
    final stats = [
      {'title': 'Members', 'value': summary['members'] ?? 0, 'icon': Icons.people_alt_rounded},
      {'title': 'Upcoming Events', 'value': summary['upcomingEvents'] ?? 0, 'icon': Icons.event_available_rounded},
      {'title': 'Announcements', 'value': summary['announcements'] ?? 0, 'icon': Icons.campaign_rounded},
      {'title': 'Resources', 'value': summary['resources'] ?? 0, 'icon': Icons.folder_rounded},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final item = stats[index];
        return _StatCard(
          title: item['title'] as String,
          value: item['value'] as int,
          icon: item['icon'] as IconData,
        );
      },
    );
  }

}

// ── Stat Card - White with Purple Accents ───────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF6D28D9).withOpacity(0.15)),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: const Color(0xFF6D28D9),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black.withOpacity(0.75),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}