import 'package:flutter/material.dart';
import '../verse_manager.dart';

class ManageVersesPage extends StatelessWidget {
  const ManageVersesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Verses')),
      body: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(children: [VerseManager()]),
      ),
    );
  }
}
