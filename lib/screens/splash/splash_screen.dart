import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../home/main_shell.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    // 1. Attempt to restore persistent session from Hive / SharedPreferences
    final savedUser = await AuthService.restoreSession();

    // 2. Smooth branded animation duration
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    // 3. If session is valid and active, transition directly to MainShell
    if (savedUser != null || AuthService.isLoggedIn) {
      debugPrint('[SplashScreen] Active session detected for ${AuthService.currentUser?.email}. Routing directly to MainShell.');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
      return;
    }

    // 4. If no active session, check if user has previously completed onboarding
    final hasOnboarded = await AuthService.hasCompletedOnboarding();
    if (!mounted) return;

    if (hasOnboarded) {
      debugPrint('[SplashScreen] Onboarding already completed. Routing to LoginScreen with saved preferences.');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      debugPrint('[SplashScreen] First run detected. Routing to OnboardingScreen.');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.white,
              AppColors.background,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.appTagline,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
