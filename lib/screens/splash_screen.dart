import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    animation = Tween<double>(
      begin: -1,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );

    controller.forward();

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const OnboardingScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF155EEF),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Logo
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 50,
                  color: Color(0xFF155EEF),
                ),
              ),

              const SizedBox(height: 25),

              // App name
              const Text(
                'CAMPUS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),

              const Text(
                'CONNECT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  letterSpacing: 4,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Discover • Connect • Achieve',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 55),

              // Moving light
              SizedBox(
                width: 260,
                height: 20,
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    return Stack(
                      children: [

                        // Line
                        Positioned(
                          left: 15,
                          right: 15,
                          top: 9,
                          child: Container(
                            height: 2,
                            color: Colors.white30,
                          ),
                        ),

                        // Moving light
                        Align(
                          alignment: Alignment(
                            animation.value,
                            0,
                          ),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white,
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}