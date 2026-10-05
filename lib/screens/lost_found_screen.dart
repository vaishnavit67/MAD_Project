import 'package:flutter/material.dart';

class LostFoundScreen extends StatelessWidget {
  const LostFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lost & Found')),
      body: const Center(child: Text('Lost & Found module managed by team member')),
    );
  }
}
