import 'package:flutter/material.dart';
import '../announcement_manager.dart';
import '../widgets/admin_drawer.dart';

class ManageAnnouncementsPage extends StatelessWidget {
  const ManageAnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const AdminDrawer(),
        appBar: AppBar(
          title: const Text('Manage Announcements'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(52),
            child: ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: TabBar(
                  labelColor: Color(0xFF7C3AED),
                  unselectedLabelColor: Colors.grey,
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(width: 3, color: Color(0xFF7C3AED)),
                    insets: EdgeInsets.symmetric(horizontal: 28),
                  ),
                  tabs: [
                    Tab(text: 'Create'),
                    Tab(text: 'Existing Announcements'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFFF8FAFC)],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
          child: const TabBarView(
            children: [
              SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: Column(children: [AnnouncementManager(showList: false)]),
              ),
              SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: Column(children: [AnnouncementManager(showForm: false)]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
