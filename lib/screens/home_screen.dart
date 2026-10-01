import 'package:flutter/material.dart';
import 'navigation_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Connect'),
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NavigationScreen(),
              ),
            );
          },
          icon: const Icon(Icons.navigation),
          label: const Text('Campus Navigation'),
        ),
      ),
    );
  }
}