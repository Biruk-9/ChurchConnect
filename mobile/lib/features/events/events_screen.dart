import 'package:flutter/material.dart';
import '../../core/config/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/search_utils.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'events_service.dart';

class EventsScreen extends StatefulWidget {
	const EventsScreen({super.key});

	@override
	State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
	bool _loading = true;
	String? _error;
	String _query = '';
	List<Map<String, dynamic>> _upcoming = const [];
	List<Map<String, dynamic>> _past = const [];
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
			final data = await EventsService.fetchAll();
			if (!mounted) return;
			setState(() {
				final split = _splitEvents(data);
				_upcoming = split.$1;
				_past = split.$2;
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
		return DefaultTabController(
			length: 2,
			child: Scaffold(
				backgroundColor: Colors.white,
				appBar: AppBar(
					backgroundColor: Colors.white,
					elevation: 0,
					foregroundColor: Colors.black87,
					title: const Text('Events', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
					bottom: PreferredSize(
						preferredSize: const Size.fromHeight(96),
						child: Column(
							children: [
								Padding(
									padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
									child: _buildSearchField(),
								),
								const TabBar(
									labelColor: Colors.black,
									unselectedLabelColor: Colors.black54,
									indicatorColor: Color(0xFF7C3AED),
									tabs: [
										Tab(text: 'Upcoming'),
										Tab(text: 'Previous'),
									],
								),
							],
						),
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
							child: TabBarView(
								children: [
									_buildBody(_upcoming, isUpcoming: true),
									_buildBody(_past, isUpcoming: false),
								],
							),
						),
					),
				),
			),
		);
	}

	Widget _buildBody(List<Map<String, dynamic>> items, {required bool isUpcoming}) {
		if (_loading) {
			return ListView(
				physics: const AlwaysScrollableScrollPhysics(),
				padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
				children: const [LoadingIndicator(message: 'Loading events...')],
			);
		}
		if (_error != null) {
			return ListView(
				physics: const AlwaysScrollableScrollPhysics(),
				padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
				children: [ErrorMessage(message: _error!, onRetry: _load)],
			);
		}

		final filtered = _filterEvents(items);
		if (items.isEmpty && _query.isEmpty) {
			return ListView(
				physics: const AlwaysScrollableScrollPhysics(),
				padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
				children: [
					Center(
						child: Text(
							isUpcoming ? 'No upcoming events' : 'No previous events',
							style: const TextStyle(color: Colors.white70, fontSize: 16),
						),
					),
				],
			);
		}
		if (filtered.isEmpty) {
			return ListView(
				physics: const AlwaysScrollableScrollPhysics(),
				padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
				children: const [
					Center(
						child: Text('No events match your search', style: TextStyle(color: Colors.white70, fontSize: 16)),
					),
				],
			);
		}

		return ListView.separated(
			physics: const AlwaysScrollableScrollPhysics(),
			padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
			itemCount: filtered.length,
			separatorBuilder: (_, __) => const SizedBox(height: 14),
			itemBuilder: (_, index) {
				final item = filtered[index];
				return _buildEventCard(item);
			},
		);
	}

	Widget _buildSearchField() {
		return TextField(
			onChanged: (value) => setState(() => _query = value.trim()),
			decoration: InputDecoration(
				prefixIcon: const Icon(Icons.search_rounded),
				hintText: 'Search events...',
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

	List<Map<String, dynamic>> _filterEvents(List<Map<String, dynamic>> items) {
		return SearchUtils.filterByQuery(items, _query, (item, q) {
			final title = (item['title'] ?? '').toString().toLowerCase();
			final desc = (item['description'] ?? '').toString().toLowerCase();
			final location = (item['location'] ?? '').toString().toLowerCase();
			final dateLabel = _formatDateOnly(_parseDate(item))?.toLowerCase() ?? '';
			final timeLabel = _formatTime(_parseDate(item), item['time']?.toString())?.toLowerCase() ?? '';
			return title.contains(q) || desc.contains(q) || location.contains(q) || dateLabel.contains(q) || timeLabel.contains(q);
		});
	}

	Widget _buildEventCard(Map<String, dynamic> item) {
		final title = item['title']?.toString() ?? 'Untitled';
		final desc = (item['description'] ?? '').toString();
		final location = item['location']?.toString();
		final parsedDate = _parseDate(item);
		final dateString = _formatDateOnly(parsedDate);
		final timeString = _formatTime(parsedDate, item['time']?.toString());

		return Container(
			padding: const EdgeInsets.all(18),
			decoration: BoxDecoration(
				color: Colors.white.withOpacity(0.97),
				borderRadius: BorderRadius.circular(22),
				boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 12))],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						crossAxisAlignment: CrossAxisAlignment.center,
						children: [
							Container(
								padding: const EdgeInsets.all(10),
								decoration: const BoxDecoration(
									shape: BoxShape.circle,
									gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
								),
								child: const Icon(Icons.event_rounded, color: Colors.white, size: 22),
							),
							const SizedBox(width: 12),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
									],
								),
						),
					],
				),
				const SizedBox(height: 12),
				Wrap(
					spacing: 10,
					runSpacing: 8,
					children: [
						if (dateString != null)
							_decoratedLabel('Date', dateString, icon: Icons.calendar_today_rounded),
						if (timeString != null && timeString.isNotEmpty)
							_decoratedLabel('Time', timeString, icon: Icons.access_time_filled_rounded, maxWidth: 120),
						if (location != null && location.isNotEmpty)
							_decoratedLabel('Location', location, icon: Icons.place_rounded),
					],
				),
				if (desc.isNotEmpty) ...[
					const SizedBox(height: 14),
					Text(desc, style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5)),
				],
				],
			),
		);
	}

	Widget _decoratedLabel(String label, String value, {required IconData icon, double maxWidth = 200}) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
			decoration: BoxDecoration(
				color: const Color(0xFFF3F4F6),
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.12)),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
					const SizedBox(width: 8),
					Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
							SizedBox(
								width: maxWidth,
								child: Text(
									value,
									style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
									overflow: TextOverflow.ellipsis,
								),
							),
						],
					),
				],
			),
		);
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

}

class _NavItem {
	const _NavItem(this.title, this.route, this.icon);

	final String title;
	final String route;
	final IconData icon;
}

	DateTime? _parseDate(Map<String, dynamic> item) {
		final raw = item['startDate']?.toString() ?? item['date']?.toString();
		if (raw == null || raw.isEmpty) return null;
		return DateTime.tryParse(raw);
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

	String? _formatDateOnly(DateTime? date) {
		if (date == null) return null;
		final day = date.day.toString().padLeft(2, '0');
		final month = date.month.toString().padLeft(2, '0');
		final year = date.year.toString().substring(2);
		return '$day/$month/$year';
	}

	String? _formatTime(DateTime? date, String? rawTime) {
		final trimmed = rawTime?.trim();
		if (trimmed != null && trimmed.isNotEmpty) return trimmed;
		if (date == null) return null;
		final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
		final minute = date.minute.toString().padLeft(2, '0');
		final period = date.hour >= 12 ? 'PM' : 'AM';
		return '$hour12:$minute $period';
	}
