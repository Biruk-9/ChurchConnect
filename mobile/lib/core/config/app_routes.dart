import 'package:flutter/widgets.dart';
import '../../features/health/health_screen.dart';
import '../../features/announcements/announcement_screen.dart';
import '../../features/events/events_screen.dart';
import '../../features/bible_verse/verse_screen.dart';
import '../../features/resources/public_resources_screen.dart';
import '../../features/resources/member_resources_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/admin/admin_dashboard.dart';

class AppRoutes {
	static const String health = '/health';
	static const String announcements = '/announcements';
	static const String events = '/events';
	static const String verse = '/verse';
	static const String resources = '/resources';
	static const String memberResources = '/member-resources';
	static const String login = '/login';
	static const String admin = '/admin';

	/// Centralized route map for MaterialApp.routes
	static Map<String, WidgetBuilder> routes() => {
				health: (_) => const HealthScreen(),
				announcements: (_) => const AnnouncementScreen(),
				events: (_) => const EventsScreen(),
				verse: (_) => const VerseScreen(),
				resources: (_) => const PublicResourcesScreen(),
				memberResources: (_) => const MemberResourcesScreen(),
				login: (_) => const LoginScreen(),
				admin: (_) => const AdminDashboard(),
			};
}
