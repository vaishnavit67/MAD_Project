import 'package:flutter/material.dart';

class BusTrackerScreen extends StatelessWidget {
  const BusTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bus Tracker')),
      body: const Center(child: Text('Bus Tracker module managed by team member')),
    );
  }
}
