import 'package:flutter/material.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 25, 28, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // =========================
              // BACK BUTTON
              // =========================

              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_rounded),
                color: const Color(0xFF101828),
              ),

              const SizedBox(height: 12),

              // =========================
              // LOGO
              // =========================

              Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 40,
                    color: Color(0xFF155EEF),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // =========================
              // TITLE
              // =========================

              const Center(
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF101828),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  'Join Campus Connect and get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF667085),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =========================
              // FULL NAME
              // =========================

              const Text(
                'Full Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF344054),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                decoration: _inputDecoration(
                  hint: 'Enter your full name',
                  icon: Icons.person_outline_rounded,
                ),
              ),

              const SizedBox(height: 18),

              // =========================
              // EMAIL
              // =========================

              const Text(
                'Email Address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF344054),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  hint: 'Enter your email address',
                  icon: Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 18),

              // =========================
              // ROLL NUMBER
              // =========================

              const Text(
                'Roll Number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF344054),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                decoration: _inputDecoration(
                  hint: 'Enter your roll number',
                  icon: Icons.badge_outlined,
                ),
              ),

              const SizedBox(height: 18),

              // =========================
              // PASSWORD
              // =========================

              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF344054),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                obscureText: _obscurePassword,
                decoration: _inputDecoration(
                  hint: 'Create a password',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // =========================
              // CONFIRM PASSWORD
              // =========================

              const Text(
                'Confirm Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF344054),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                obscureText: _obscureConfirmPassword,
                decoration: _inputDecoration(
                  hint: 'Confirm your password',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword =
                            !_obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // =========================
              // SIGN UP BUTTON
              // =========================

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    // Real registration will be added later.
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF155EEF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // =========================
              // OR
              // =========================

              Row(
                children: [
                  const Expanded(
                    child: Divider(
                      color: Color(0xFFD0D5DD),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const Expanded(
                    child: Divider(
                      color: Color(0xFFD0D5DD),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // =========================
              // GOOGLE
              // =========================

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Google authentication later
                  },
                  icon: const Icon(
                    Icons.g_mobiledata_rounded,
                    size: 30,
                    color: Color(0xFF4285F4),
                  ),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: Color(0xFF344054),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFFE4E7EC),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // =========================
              // LOGIN LINK
              // =========================

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: Color(0xFF667085),
                    ),
                  ),

                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Color(0xFF155EEF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE4E7EC),
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE4E7EC),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF155EEF),
          width: 2,
        ),
      ),
    );
  }
}