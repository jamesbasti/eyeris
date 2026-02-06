// lib/ui/home_screen.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'camera_screen.dart';  // We'll create this next

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eyeris Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Eyeris',
              style: TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt, size: 40),
              label: const Text('Open Camera', style: TextStyle(fontSize: 24)),
              onPressed: () async {
                // Request camera permission
                final status = await Permission.camera.request();
                if (status.isGranted && mounted) {
                  // Navigate to camera screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CameraScreen()),
                  );
                } else {
                  // Show message if denied
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camera permission denied')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}