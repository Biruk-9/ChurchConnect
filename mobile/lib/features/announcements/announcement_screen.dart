import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';
import '../../core/config/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/search_utils.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'announcement_service.dart';
import 'announcement_model.dart';

class AnnouncementScreen extends StatefulWidget {
	const AnnouncementScreen({super.key});

	@override
	State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
	bool _loading = true;
	String? _error;
	String _query = '';
	List<Announcement> _items = const [];
	String? _userName;
	bool _isLoggedIn = false;

	@override
	void initState() {
		super.initState();
		_loadUser();
		_load();
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

	Future<void> _load() async {
		setState(() {
			_loading = true;
			_error = null;
		});
		try {
			final data = await AnnouncementService.fetchPublic();
			if (!mounted) return;
			setState(() {
				_items = data;
			});
		} catch (e) {
			if (!mounted) return;
			setState(() {
				_error = e.toString();
			});
		} finally {
			if (!mounted) return;
			setState(() {
				_loading = false;
			});
		}
	}

	@override
	Widget build(BuildContext context) {
		final navItems = _navItems;
		return Scaffold(
			backgroundColor: Colors.white,
			appBar: AppBar(
				backgroundColor: Colors.white,
				elevation: 0,
				foregroundColor: Colors.black87,
				title: const Text(
					'Announcements',
					style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
				),
			),
			drawer: _buildDrawer(context, navItems),
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
						onRefresh: _load,
						child: _buildBody(),
					),
				),
			),
		);
	}

	Widget _buildBody() {
		if (_loading) {
			return ListView(
				physics: const AlwaysScrollableScrollPhysics(),
				padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
				children: const [
					LoadingIndicator(message: 'Loading announcements...'),
				],
			);
		}
		if (_error != null) {
			return ListView(
				physics: const AlwaysScrollableScrollPhysics(),
				padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
				children: [
					ErrorMessage(message: _error!, onRetry: _load),
				],
			);
		}

		final filtered = _filteredAnnouncements();
		final children = <Widget>[
			Padding(
				padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
				child: _buildSearchField(),
			),
			if (filtered.isEmpty)
				const Padding(
					padding: EdgeInsets.only(top: 12),
					child: Center(
						child: Text('No announcements match your search', style: TextStyle(color: Colors.white70, fontSize: 16)),
					),
				)
			else ...[
				...filtered.map((item) => Padding(
					padding: const EdgeInsets.only(bottom: 14),
					child: _buildAnnouncementCard(item),
				)),
			],
		];

		if (_items.isEmpty && _query.isEmpty) {
			return ListView(
				physics: const AlwaysScrollableScrollPhysics(),
				padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
				children: [
					_buildSearchField(),
					const SizedBox(height: 16),
					const Center(
						child: Text('No announcements yet', style: TextStyle(color: Colors.white70, fontSize: 16)),
					),
				],
			);
		}

		return ListView(
			physics: const AlwaysScrollableScrollPhysics(),
			padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
			children: children,
		);
	}

	Widget _buildSearchField() {
		return TextField(
			onChanged: (value) => setState(() => _query = value.trim()),
			decoration: InputDecoration(
				prefixIcon: const Icon(Icons.search_rounded),
				hintText: 'Search announcements...',
				filled: true,
				fillColor: const Color(0xFFF1F5F9),
				contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(14),
					borderSide: BorderSide(color: Colors.grey.shade300),
				),
				enabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(14),
					borderSide: BorderSide(color: Colors.grey.shade300),
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(14),
					borderSide: const BorderSide(color: Color(0xFF7C3AED)),
				),
				suffixIcon: _query.isNotEmpty
					? IconButton(
						icon: const Icon(Icons.close_rounded),
						onPressed: () => setState(() => _query = ''),
					)
					: null,
			),
		);
	}

	List<Announcement> _filteredAnnouncements() {
		return SearchUtils.filterByQuery(_items, _query, (item, q) {
			final title = item.title.toLowerCase();
			final content = item.content.toLowerCase();
			final dateLabel = _formatDate(item.createdAt)?.toLowerCase() ?? '';
			return title.contains(q) || content.contains(q) || dateLabel.contains(q);
		});
	}

	Widget _buildAnnouncementCard(Announcement item) {
		final title = item.title.isNotEmpty ? item.title : 'Untitled';
		final subtitle = item.content.trim();
		final dateLabel = _formatDate(item.createdAt);
		final resolvedImage = _resolveImageUrl(item.imageUrl);
		final hasImage = resolvedImage != null;

		return Container(
			padding: const EdgeInsets.all(18),
			decoration: BoxDecoration(
				color: Colors.white.withOpacity(0.95),
				borderRadius: BorderRadius.circular(20),
				boxShadow: [
					BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 12)),
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Container(
								padding: const EdgeInsets.all(10),
								decoration: const BoxDecoration(
									shape: BoxShape.circle,
									gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
								),
								child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
							),
							const SizedBox(width: 12),
							expandedTitleAndDate(title, dateLabel),
						],
					),
					if (subtitle.isNotEmpty) ...[
						const SizedBox(height: 12),
						Text(
							subtitle,
							style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.45),
						),
					],
					if (hasImage) ...[
						const SizedBox(height: 12),
						GestureDetector(
							onTap: () => _showImagePreview(context, resolvedImage!),
							child: ClipRRect(
								borderRadius: BorderRadius.circular(16),
								child: AspectRatio(
									aspectRatio: 16 / 11,
									child: Image.network(
										resolvedImage!,
										fit: BoxFit.cover,
										width: double.infinity,
										loadingBuilder: (context, child, loadingProgress) {
											if (loadingProgress == null) return child;
											return Container(
												color: Colors.grey.shade200,
												child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
											);
										},
										errorBuilder: (_, __, ___) => Container(
											color: Colors.grey.shade200,
											child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
										),
									),
								),
							),
						),
						],
				],
			),
		);
	}

	void _showImagePreview(BuildContext context, String url) {
		showDialog<void>(
			context: context,
			builder: (dialogContext) {
				return Dialog(
					backgroundColor: Colors.transparent,
					insetPadding: const EdgeInsets.all(12),
					child: Stack(
						children: [
							InteractiveViewer(
								child: Center(
									child: ClipRRect(
										borderRadius: BorderRadius.circular(12),
										child: Image.network(
											url,
											fit: BoxFit.contain,
											loadingBuilder: (context, child, loadingProgress) {
												if (loadingProgress == null) return child;
												return Container(
													color: Colors.grey.shade200,
													child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
												);
											},
											errorBuilder: (context, error, stackTrace) => const Center(
												child: Text('Image unavailable', style: TextStyle(color: Colors.white70)),
											),
										),
									),
								),
							),
							Positioned(
								top: 8,
								right: 8,
								child: IconButton(
									icon: const Icon(Icons.close_rounded, color: Colors.white),
									onPressed: () => Navigator.of(dialogContext).pop(),
								),
							),
						],
					),
				);
			},
		);
	}

	String? _resolveImageUrl(String? url) {
			final value = url?.trim();
			if (value == null || value.isEmpty) return null;
			if (value.startsWith('http')) return value;
			return '${ApiConfig.baseUrl}$value';
		}

	Drawer _buildDrawer(BuildContext context, List<_NavItem> items) {
		final initial = (_userName != null && _userName!.isNotEmpty) ? _userName!.substring(0, 1).toUpperCase() : 'C';
		final status = _isLoggedIn ? 'Member' : 'Guest';
		final displayName = _userName ?? 'Welcome';
		return Drawer(
			child: ListView(
				padding: EdgeInsets.zero,
				children: [
					DrawerHeader(
						decoration: const BoxDecoration(
							gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
						),
						child: Row(
							children: [
								CircleAvatar(
									radius: 26,
									backgroundColor: Colors.white24,
									child: const Icon(Icons.church_rounded, color: Colors.white, size: 28),
								),
								const SizedBox(width: 12),
								Expanded(
									child: Column(
										mainAxisAlignment: MainAxisAlignment.center,
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
											Text(status, style: TextStyle(color: Colors.white.withOpacity(0.85))),
										],
									),
								),
							],
						),
					),
					...items.map((item) => ListTile(
						leading: Icon(item.icon, color: const Color(0xFF7C3AED)),
						title: Text(item.title),
						onTap: () {
							Navigator.of(context).pop();
							Navigator.of(context).pushNamed(item.route);
						},
					)),
				],
			),
		);
	}

	List<_NavItem> get _navItems => const [
		_NavItem('Home', AppRoutes.home, Icons.home_rounded),
		_NavItem('Announcements', AppRoutes.announcements, Icons.campaign_rounded),
		_NavItem('Events', AppRoutes.events, Icons.event_rounded),
		_NavItem('Resources', AppRoutes.resources, Icons.menu_book_rounded),
		_NavItem('Member Resources', AppRoutes.memberResources, Icons.lock_rounded),
	];

	Widget expandedTitleAndDate(String title, String? dateLabel) {
		return Expanded(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						title,
						style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
					),
					if (dateLabel != null) ...[
						const SizedBox(height: 6),
						Text(
							dateLabel,
							style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
						),
					],
				],
			),
		);
	}

	String? _formatDate(DateTime? date) {
		if (date == null) return null;
		final day = date.day.toString().padLeft(2, '0');
		final month = date.month.toString().padLeft(2, '0');
		final year = date.year.toString().substring(2);
		final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
		final minute = date.minute.toString().padLeft(2, '0');
		final period = date.hour >= 12 ? 'PM' : 'AM';
		return '$day/$month/$year • $hour:$minute $period';
	}
}

class _NavItem {
	const _NavItem(this.title, this.route, this.icon);

	final String title;
	final String route;
	final IconData icon;
}
