import 'package:flutter/material.dart';
import '../../core/config/app_routes.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';

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
	Map<String, dynamic>? _summary;
	Map<String, dynamic>? _recent;
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
				setState(() {
					_authed = afterLogin;
					_isAdmin = role == 'admin';
					_checking = false;
				});
				if (afterLogin && role == 'admin') {
					await _loadDashboard();
				}
			} else {
				final role = await AuthService.getRole();
				setState(() {
					_authed = true;
					_isAdmin = role == 'admin';
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
			final recent = await AdminService.fetchRecent();
			if (!mounted) return;
			setState(() {
				_summary = summary;
				_recent = recent;
				_loadingData = false;
			});
		} on AdminAuthException {
			await AuthService.logout();
			if (!mounted) return;
			setState(() {
				_authed = false;
				_isAdmin = false;
				_loadingData = false;
				_dashboardError = 'Session expired. Please log in again.';
			});
		} on AdminForbiddenException catch (e) {
			if (!mounted) return;
			setState(() {
				_isAdmin = false;
				_loadingData = false;
				_dashboardError = e.message;
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
		if (!_authed) {
			return Scaffold(
				body: Center(
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: const [
							Text('Please log in to continue'),
						],
					),
				),
			);
		}
		if (!_isAdmin) {
			return Scaffold(
				body: Center(
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							const Text('Admin access required'),
							const SizedBox(height: 12),
							OutlinedButton(
								onPressed: () async {
									await AuthService.logout();
									if (!mounted) return;
									await Navigator.of(context).pushNamed(AppRoutes.login);
									final role = await AuthService.getRole();
									setState(() {
										_authed = role != null;
										_isAdmin = role == 'admin';
									});
								if (_isAdmin) {
									await _loadDashboard();
								}
								},
								child: const Text('Login as admin'),
							),
						],
					),
				),
			);
		}

		return Scaffold(
			appBar: AppBar(title: const Text('Admin Dashboard')),
			body: RefreshIndicator(
				onRefresh: _loadDashboard,
				child: SingleChildScrollView(
					physics: const AlwaysScrollableScrollPhysics(),
					padding: const EdgeInsets.all(16),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							const Text('Welcome, Admin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
							const SizedBox(height: 12),
							const Text('Quickly review church activity and jump into management screens.'),
							const SizedBox(height: 24),
							if (_loadingData) ...[
								const LoadingIndicator(message: 'Loading dashboard...'),
							] else if (_dashboardError != null) ...[
								ErrorMessage(message: _dashboardError!),
								const SizedBox(height: 12),
								ElevatedButton(
									onPressed: _loadDashboard,
									child: const Text('Retry'),
								),
							] else ...[
								const Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
								const SizedBox(height: 12),
								_wrapStats(),
								const SizedBox(height: 24),
								const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
								const SizedBox(height: 12),
								_buildRecentSection('Announcements', _recent?['announcements'] as List<dynamic>?),
								const SizedBox(height: 12),
								_buildRecentSection('Events', _recent?['events'] as List<dynamic>?),
								const SizedBox(height: 12),
								_buildRecentSection('Resources', _recent?['resources'] as List<dynamic>?),
								const SizedBox(height: 24),
								const Text('Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
								const SizedBox(height: 8),
								_managementShortcuts(),
							],
						],
					),
				),
			),
		);
	}

	Widget _wrapStats() {
		final summary = _summary ?? {};
		final cards = [
			{'title': 'Members', 'icon': Icons.group_outlined, 'value': summary['members'] ?? 0, 'color': Colors.blue},
			{'title': 'Upcoming Events', 'icon': Icons.event_available_outlined, 'value': summary['upcomingEvents'] ?? 0, 'color': Colors.deepPurple},
			{'title': 'Announcements', 'icon': Icons.campaign_outlined, 'value': summary['announcements'] ?? 0, 'color': Colors.teal},
			{'title': 'Resources', 'icon': Icons.folder_special_outlined, 'value': summary['resources'] ?? 0, 'color': Colors.orange},
		];

		return Wrap(
			spacing: 12,
			runSpacing: 12,
			children: cards
				.map((c) => _StatCard(
					title: c['title'] as String,
					icon: c['icon'] as IconData,
					value: c['value'],
					color: c['color'] as Color,
				))
				.toList(),
		);
	}

	Widget _buildRecentSection(String title, List<dynamic>? items) {
		final list = items ?? [];
		return Card(
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
			child: Padding(
				padding: const EdgeInsets.all(12),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
						const SizedBox(height: 8),
						if (list.isEmpty)
							const Text('No items yet', style: TextStyle(color: Colors.grey))
						else
							Column(
								children: list.map((item) {
									final map = item as Map<String, dynamic>;
									final itemTitle = (map['title'] ?? 'Untitled').toString();
									final createdAt = DateTime.tryParse(map['createdAt']?.toString() ?? '');
									final subtitle = createdAt != null
										? 'Added ${createdAt.toLocal().toString().split('.')[0]}'
										: 'Recently added';
									return ListTile(
										contentPadding: EdgeInsets.zero,
										dense: true,
										title: Text(itemTitle, style: const TextStyle(fontWeight: FontWeight.w500)),
										subtitle: Text(subtitle),
										leading: const Icon(Icons.fiber_manual_record, size: 14, color: Colors.green),
									);
								}).toList(),
							),
					],
				),
			),
		);
	}

	Widget _managementShortcuts() {
		final items = [
			{
				'title': 'Announcements',
				'icon': Icons.campaign_outlined,
				'description': 'Post updates for members.',
				'route': AppRoutes.manageAnnouncements,
				'color': Colors.teal,
			},
			{
				'title': 'Events',
				'icon': Icons.event_note_outlined,
				'description': 'Schedule and track attendance.',
				'route': AppRoutes.manageEvents,
				'color': Colors.deepPurple,
			},
			{
				'title': 'Resources',
				'icon': Icons.folder_special_outlined,
				'description': 'Share files and links.',
				'route': AppRoutes.manageResources,
				'color': Colors.orange,
			},
			{
				'title': 'Users',
				'icon': Icons.admin_panel_settings_outlined,
				'description': 'Manage member access.',
				'route': AppRoutes.manageUsers,
				'color': Colors.blue,
			},
		];

		return Wrap(
			spacing: 12,
			runSpacing: 12,
			children: items
				.map((item) => _ManagementCard(
					title: item['title'] as String,
					icon: item['icon'] as IconData,
					description: item['description'] as String,
					color: item['color'] as Color,
					onTap: () => Navigator.of(context).pushNamed(item['route'] as String),
				))
				.toList(),
		);
	}
}

class _StatCard extends StatelessWidget {
	const _StatCard({required this.title, required this.icon, required this.value, required this.color});

	final String title;
	final IconData icon;
	final dynamic value;
	final Color color;

	@override
	Widget build(BuildContext context) {
		return Card(
			color: color.withOpacity(0.08),
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
			child: SizedBox(
				width: 180,
				height: 110,
				child: Padding(
					padding: const EdgeInsets.all(12),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							Icon(icon, color: color, size: 28),
							Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
							Text(value.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
						],
					),
				),
			),
		);
	}
}

class _ManagementCard extends StatelessWidget {
	const _ManagementCard({
		required this.title,
		required this.icon,
		required this.description,
		required this.color,
		required this.onTap,
	});

	final String title;
	final IconData icon;
	final String description;
	final Color color;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return SizedBox(
			width: 220,
			height: 120,
			child: Card(
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
				elevation: 1,
				child: InkWell(
					borderRadius: BorderRadius.circular(12),
					onTap: onTap,
					child: Padding(
						padding: const EdgeInsets.all(12),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							mainAxisAlignment: MainAxisAlignment.spaceBetween,
							children: [
								Container(
									padding: const EdgeInsets.all(8),
									decoration: BoxDecoration(
										color: color.withOpacity(0.12),
										borderRadius: BorderRadius.circular(10),
									),
									child: Icon(icon, color: color, size: 22),
								),
								Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
								Text(description, style: const TextStyle(color: Colors.black87)),
								Row(
									children: [
										Text('Open', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
										const SizedBox(width: 4),
										Icon(Icons.arrow_forward_rounded, color: color, size: 16),
									],
								),
							],
						),
					),
				),
			),
		);
	}
}
