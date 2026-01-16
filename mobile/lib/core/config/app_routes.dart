import 'package:flutter/material.dart';
import '../../features/home/home_screen.dart';
import '../../features/announcements/announcement_screen.dart';
import '../../features/events/events_screen.dart';
import '../../features/resources/public_resources_screen.dart';
import '../../features/resources/member_resources_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/admin/admin_dashboard.dart';
import '../../features/admin/screens/manage_announcements_page.dart';
import '../../features/admin/screens/manage_events_page.dart';
import '../../features/admin/screens/manage_resources_page.dart';
import '../../features/admin/screens/manage_users_page.dart';
import '../../features/admin/screens/manage_verses_page.dart';
import '../../features/splash/splash_screen.dart';

class AppRoutes {
	static const String home = '/';
	static const String splash = '/splash';
	static const String announcements = '/announcements';
	static const String events = '/events';
	static const String resources = '/resources';
	static const String memberResources = '/member-resources';
	static const String login = '/login';
	static const String admin = '/admin';
	static const String manageAnnouncements = '/admin/announcements';
	static const String manageEvents = '/admin/events';
	static const String manageResources = '/admin/resources';
	static const String manageUsers = '/admin/users';
	static const String manageVerses = '/admin/verses';

	/// Centralized route map for MaterialApp.routes
	static Map<String, WidgetBuilder> routes() => {
				splash: (_) => const SplashScreen(),
				home: (_) => const HomeScreen(),
				announcements: (_) => const AnnouncementScreen(),
				events: (_) => const EventsScreen(),
				resources: (_) => const PublicResourcesScreen(),
				memberResources: (_) => const MemberResourcesScreen(),
				login: (_) => const LoginScreen(),
				admin: (_) => const AdminDashboard(),
				manageAnnouncements: (_) => const ManageAnnouncementsPage(),
				manageEvents: (_) => const ManageEventsPage(),
				manageResources: (_) => const ManageResourcesPage(),
				manageUsers: (_) => const ManageUsersPage(),
				manageVerses: (_) => const ManageVersesPage(),
			};
}
