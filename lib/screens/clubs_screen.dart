import 'package:flutter/material.dart';

class ClubsScreen extends StatelessWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clubs')),
      body: const Center(child: Text('Clubs module managed by team member')),
    );
  }
}
