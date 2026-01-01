import 'package:flutter/material.dart';
import '../resource_manager.dart';

class ManageResourcesPage extends StatelessWidget {
  const ManageResourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Resources')),
      body: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(children: [ResourceManager()]),
      ),
    );
  }
}
