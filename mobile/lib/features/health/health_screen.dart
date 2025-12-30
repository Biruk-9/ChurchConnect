import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  bool? isConnected;

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    final result = await ApiService.healthCheck();
    setState(() {
      isConnected = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChurchConnect'),
      ),
      body: Center(
        child: isConnected == null
            ? const CircularProgressIndicator()
            : isConnected!
                ? const Text(
                    '✅ Backend Connected',
                    style: TextStyle(fontSize: 20, color: Colors.green),
                  )
                : const Text(
                    '❌ Backend Not Reachable',
                    style: TextStyle(fontSize: 20, color: Colors.red),
                  ),
      ),
    );
  }
}
