import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
	const AdminDashboard({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Admin Dashboard')),
			body: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: const [
						Text('Welcome, Admin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
						SizedBox(height: 12),
						Text('Use the admin screens to manage announcements, events, and resources.'),
					],
				),
			),
		);
	}
}
