import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/api_config.dart';
import '../../core/config/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/search_utils.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'resource_service.dart';

class MemberResourcesScreen extends StatefulWidget {
	const MemberResourcesScreen({super.key});

	@override
	State<MemberResourcesScreen> createState() => _MemberResourcesScreenState();
}

class _MemberResourcesScreenState extends State<MemberResourcesScreen> {
	bool _loading = true;
	String? _error;
	String _query = '';
	List<Map<String, dynamic>> _items = const [];
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
			final data = await ResourceService.fetchMember();
			setState(() {
				_items = data;
			});
		} catch (e) {
			setState(() {
				_error = e.toString();
			});
		} finally {
			setState(() {
				_loading = false;
			});
		}
	}

	@override
	Widget build(BuildContext context) {
		final navItems = _navItems;
		final pdf = _filterByType('pdf');
		final audio = _filterByType('audio');
		final video = _filterByType('video');
		final images = _filterByType('image');
		return DefaultTabController(
			length: 4,
			child: Scaffold(
				backgroundColor: Colors.white,
				appBar: AppBar(
					title: const Text('Member Resources', style: TextStyle(fontWeight: FontWeight.w800)),
					elevation: 0,
					backgroundColor: Colors.white,
					foregroundColor: Colors.black,
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
										Tab(text: 'PDF'),
										Tab(text: 'Audio'),
										Tab(text: 'Video'),
										Tab(text: 'Images'),
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
									_buildBody(pdf),
									_buildBody(audio),
									_buildBody(video),
									_buildBody(images),
								],
							),
						),
					),
				),
			),
		);
	}

	Widget _buildBody(List<Map<String, dynamic>> items) {
		if (_loading) {
			return ListView(
				physics: const AlwaysScrollableScrollPhysics(),
				padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
				children: const [LoadingIndicator(message: 'Loading resources...')],
			);
		}
		if (_error != null) {
			final msg = _error!;
			if (msg.contains('Authentication required') || msg.contains('Not authenticated')) {
				return ListView(
					physics: const AlwaysScrollableScrollPhysics(),
					padding: const EdgeInsets.fromLTRB(16, 60, 16, 32),
					children: [
						Center(
							child: Column(
								mainAxisSize: MainAxisSize.min,
								children: [
									const Text('Please log in to view member resources', style: TextStyle(color: Colors.white70, fontSize: 16)),
									const SizedBox(height: 14),
									OutlinedButton(
										onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
										style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
										child: const Text('Go to Login'),
									),
								],
							),
						),
					],
				);
			}
			if (msg.contains('Members only')) {
				return ListView(
					physics: const AlwaysScrollableScrollPhysics(),
					padding: const EdgeInsets.fromLTRB(16, 60, 16, 32),
					children: const [
						Center(child: Text('This content is available to members only', style: TextStyle(color: Colors.white70, fontSize: 16))),
					],
				);
			}
			return ListView(
				physics: const AlwaysScrollableScrollPhysics(),
				padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
				children: [ErrorMessage(message: msg, onRetry: _load)],
			);
		}
		if (_items.isEmpty) {
			return ListView(
				physics: const AlwaysScrollableScrollPhysics(),
				padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
				children: const [
					Center(child: Text('No member resources available', style: TextStyle(color: Colors.white70, fontSize: 16))),
				],
			);
		}

		if (items.isEmpty) {
			return ListView(
				physics: const AlwaysScrollableScrollPhysics(),
				padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
				children: const [
					Center(child: Text('No resources available', style: TextStyle(color: Colors.white70, fontSize: 16))),
				],
			);
		}

		return ListView.separated(
			physics: const AlwaysScrollableScrollPhysics(),
			padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
			itemCount: items.length,
			separatorBuilder: (_, __) => const SizedBox(height: 14),
			itemBuilder: (_, index) {
				final item = items[index];
				return _buildResourceCard(item, isMember: true);
			},
		);
	}

	Future<void> _openUrl(BuildContext context, String url) async {
		final uri = Uri.tryParse(url);
		if (uri == null) {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Invalid link: $url')),
			);
			return;
		}
		if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Could not open link')),
			);
		}
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

	List<Map<String, dynamic>> _filterByType(String type) {
		final typedItems = _items.where((item) {
			final media = (item['mediaType'] ?? item['category'] ?? '').toString().toLowerCase();
			return media == type;
		}).toList();
		return SearchUtils.filterByQuery(typedItems, _query, (item, q) {
			final title = (item['title'] ?? '').toString().toLowerCase();
			final desc = (item['description'] ?? '').toString().toLowerCase();
			return title.contains(q) || desc.contains(q);
		});
	}

	Widget _buildSearchField() {
		return TextField(
			onChanged: (value) => setState(() => _query = value.trim()),
			decoration: InputDecoration(
				prefixIcon: const Icon(Icons.search_rounded),
				hintText: 'Search resources...',
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
	Widget _buildResourceCard(Map<String, dynamic> item, {required bool isMember}) {
		final title = item['title']?.toString() ?? 'Untitled';
		final desc = item['description']?.toString() ?? '';
		final url = (item['url'] ?? item['fileUrl'])?.toString();
		final thumb = (item['thumbnail'] ?? item['thumbnailUrl'] ?? item['thumb'] ?? item['image'] ?? item['imageUrl'])?.toString();
		final mediaType = (item['mediaType'] ?? item['category'] ?? '').toString().toLowerCase();
		final resolvedUrl = _resolveMediaUrl(url);
		final isImage = mediaType == 'image';
		final isVideo = mediaType == 'video';
		final isPdf = mediaType == 'pdf';
		final isAudio = mediaType == 'audio';

		return Container(
			padding: const EdgeInsets.all(18),
			decoration: BoxDecoration(
				color: Colors.white.withOpacity(0.97),
				borderRadius: BorderRadius.circular(20),
				boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 18, offset: const Offset(0, 10))],
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
								child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
							),
							const SizedBox(width: 12),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
									],
								),
							),
						],
					),
					if (desc.isNotEmpty) ...[
						const SizedBox(height: 12),
						Text(desc, style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5)),
					],
					if (isImage && resolvedUrl != null) ...[
						const SizedBox(height: 12),
						GestureDetector(
							onTap: () => _showImagePreview(context, resolvedUrl),
							child: _buildImagePreview(resolvedUrl),
						),
					],
					if (isVideo && resolvedUrl != null) ...[
						const SizedBox(height: 12),
						GestureDetector(
							onTap: () => _showVideoPreview(context, resolvedUrl, thumbnail: thumb),
							child: _buildVideoPreview(resolvedUrl, thumbnail: thumb),
						),
					],
					if (resolvedUrl != null && (isPdf || isAudio)) ...[
						const SizedBox(height: 14),
						Align(
							alignment: Alignment.centerLeft,
							child: TextButton.icon(
								onPressed: () => _openUrl(context, resolvedUrl),
								style: TextButton.styleFrom(
									padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
									backgroundColor: isPdf ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF),
									foregroundColor: isPdf ? const Color(0xFFEA580C) : const Color(0xFF1D4ED8),
									shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
								),
								icon: Icon(isPdf ? Icons.picture_as_pdf_outlined : Icons.headphones_rounded, size: 18),
								label: Text(isPdf ? 'Open PDF' : 'Play Audio', overflow: TextOverflow.ellipsis),
							),
						),
					],
					if (resolvedUrl != null && !isImage && !isVideo && !isPdf && !isAudio) ...[
						const SizedBox(height: 14),
						Align(
							alignment: Alignment.centerLeft,
							child: TextButton.icon(
								onPressed: () => _openUrl(context, resolvedUrl),
								style: TextButton.styleFrom(
									padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
									backgroundColor: const Color(0xFFEEF2FF),
									foregroundColor: const Color(0xFF4338CA),
									shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
								),
								icon: const Icon(Icons.link_rounded, size: 18),
								label: Text(resolvedUrl, overflow: TextOverflow.ellipsis),
							),
						),
					],
					if (isMember) ...[
						const SizedBox(height: 12),
						Align(
							alignment: Alignment.bottomRight,
							child: Container(
								padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
								decoration: BoxDecoration(
									color: const Color(0xFFEFF6FF),
									borderRadius: BorderRadius.circular(12),
								),
								child: const Text('Member resource', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
							),
						),
					],
				],
			),
		);
	}

	Widget _buildImagePreview(String url) {
		return ClipRRect(
			borderRadius: BorderRadius.circular(16),
			child: AspectRatio(
				aspectRatio: 16 / 11,
				child: Image.network(
					url,
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
		);
	}

	Widget _buildVideoPreview(String url, {String? thumbnail}) {
		return ClipRRect(
			borderRadius: BorderRadius.circular(16),
			child: Stack(
				children: [
					Container(
						height: 180,
						width: double.infinity,
						decoration: BoxDecoration(
							gradient: const LinearGradient(
								colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
								begin: Alignment.topLeft,
								end: Alignment.bottomRight,
							),
							image: (thumbnail != null && thumbnail.isNotEmpty)
								? DecorationImage(image: NetworkImage(thumbnail), fit: BoxFit.cover)
								: (url.endsWith('.jpg') || url.endsWith('.png') || url.endsWith('.jpeg')
									? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
									: null),
						),
					),
					Positioned.fill(
						child: Container(
							color: Colors.black.withOpacity(0.35),
						),
					),
					const Positioned.fill(
						child: Center(
							child: CircleAvatar(
								radius: 30,
								backgroundColor: Colors.white,
								child: Icon(Icons.play_arrow_rounded, color: Colors.black87, size: 36),
							),
						),
					),
				],
			),
		);
	}

	void _showVideoPreview(BuildContext context, String url, {String? thumbnail}) {
		showDialog<void>(
			context: context,
			builder: (dialogContext) {
				return Dialog(
					backgroundColor: Colors.transparent,
					insetPadding: const EdgeInsets.all(16),
					child: Stack(
						children: [
							Column(
								mainAxisSize: MainAxisSize.min,
								children: [
									_buildVideoPreview(url, thumbnail: thumbnail),
									const SizedBox(height: 12),
									TextButton.icon(
										onPressed: () {
											Navigator.of(dialogContext).pop();
											_openUrl(context, url);
										},
										style: TextButton.styleFrom(
											padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
											backgroundColor: const Color(0xFFEEF2FF),
											foregroundColor: const Color(0xFF4338CA),
											shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
										),
										icon: const Icon(Icons.play_circle_outline_rounded),
										label: const Text('Open video'),
									),
								],
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

	String? _resolveMediaUrl(String? url) {
		final value = url?.trim();
		if (value == null || value.isEmpty) return null;
		if (value.startsWith('http')) return value;
		return '${ApiConfig.baseUrl}$value';
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
}

class _NavItem {
	const _NavItem(this.title, this.route, this.icon);

	final String title;
	final String route;
	final IconData icon;
}
