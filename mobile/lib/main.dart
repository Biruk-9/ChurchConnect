import 'package:flutter/material.dart';
import 'core/config/app_routes.dart';
import 'core/utils/constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: AppRoutes.routes(),
      // Use initialRoute so '/' comes from the routes table.
      initialRoute: AppRoutes.home,
    );
  }
}

// Removed the default counter screen and wired HealthScreen as home.
