import 'package:flutter/material.dart';
import '../announcement_manager.dart';

class ManageAnnouncementsPage extends StatelessWidget {
  const ManageAnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Announcements')),
      body: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(children: [AnnouncementManager()]),
      ),
    );
  }
}
