import 'package:flutter/material.dart';
import '../../features/home/home_screen.dart';
import '../../features/health/health_screen.dart';
import '../../features/announcements/announcement_screen.dart';
import '../../features/events/events_screen.dart';
import '../../features/resources/public_resources_screen.dart';
import '../../features/resources/member_resources_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/admin/admin_dashboard.dart';
import '../../features/admin/announcement_manager.dart';
import '../../features/admin/event_manager.dart';
import '../../features/admin/resource_manager.dart';
import '../../features/admin/user_manager.dart';
import '../../features/admin/verse_manager.dart';

class AppRoutes {
	static const String home = '/';
	static const String health = '/health';
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
				home: (_) => const HomeScreen(),
				health: (_) => const HealthScreen(),
				announcements: (_) => const AnnouncementScreen(),
				events: (_) => const EventsScreen(),
				resources: (_) => const PublicResourcesScreen(),
				memberResources: (_) => const MemberResourcesScreen(),
				login: (_) => const LoginScreen(),
				admin: (_) => const AdminDashboard(),
				manageAnnouncements: (_) => Scaffold(
					appBar: AppBar(title: const Text('Manage Announcements')),
					body: SingleChildScrollView(
						physics: const AlwaysScrollableScrollPhysics(),
						padding: const EdgeInsets.all(16),
						child: Column(children: const [AnnouncementManager()]),
					),
				),
				manageEvents: (_) => Scaffold(
					appBar: AppBar(title: const Text('Manage Events')),
					body: SingleChildScrollView(
						physics: const AlwaysScrollableScrollPhysics(),
						padding: const EdgeInsets.all(16),
						child: Column(children: const [EventManager()]),
					),
				),
				manageResources: (_) => Scaffold(
					appBar: AppBar(title: const Text('Manage Resources')),
					body: SingleChildScrollView(
						physics: const AlwaysScrollableScrollPhysics(),
						padding: const EdgeInsets.all(16),
						child: Column(children: const [ResourceManager()]),
					),
				),
				manageUsers: (_) => Scaffold(
					appBar: AppBar(title: const Text('Manage Users')),
					body: SingleChildScrollView(
						physics: const AlwaysScrollableScrollPhysics(),
						padding: const EdgeInsets.all(16),
						child: Column(children: const [UserManager()]),
					),
				),
				manageVerses: (_) => Scaffold(
					appBar: AppBar(title: const Text('Manage Verses')),
					body: SingleChildScrollView(
						physics: const AlwaysScrollableScrollPhysics(),
						padding: const EdgeInsets.all(16),
						child: Column(children: const [VerseManager()]),
					),
				),
			};
}
