import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _selectedRole = 'Student';

  final List<String> _roles = ['Student', 'Faculty', 'Visitor'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _rollNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getEmailHint() {
    switch (_selectedRole) {
      case 'Visitor':
        return 'user@gmail.com';
      case 'Faculty':
        return 'faculty@cb.amrita.edu';
      case 'Student':
      default:
        return 'student@cb.students.amrita.edu';
    }
  }

  String _getEmailHelperText() {
    switch (_selectedRole) {
      case 'Visitor':
        return 'Visitors must register with @gmail.com';
      case 'Faculty':
        return 'Faculty must register with @cb.amrita.edu';
      case 'Student':
      default:
        return 'Students must register with @cb.students.amrita.edu';
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final rollNumber = _selectedRole == 'Student'
        ? _rollNumberController.text.trim()
        : (_selectedRole == 'Faculty' ? 'FAC-${DateTime.now().millisecondsSinceEpoch % 10000}' : 'VISITOR');
    final password = _passwordController.text;

    try {
      final AuthResult result = await _authService.signUpUser(
        name: name,
        email: email,
        phone: phone,
        rollNumber: rollNumber,
        password: password,
        role: _selectedRole,
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(result.message)),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LoginScreen(initialIdentity: email),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(result.message)),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Icon(Icons.school, size: 64, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select your role and fill in your details',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 20),

                // ROLE SELECTOR TABS
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: _roles.map((role) {
                      final isSelected = _selectedRole == role;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = role;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              role,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // NAME
                AppTextField(
                  controller: _nameController,
                  hintText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (val) => FormValidators.validateName(val ?? ''),
                ),
                const SizedBox(height: 14),

                // EMAIL
                AppTextField(
                  controller: _emailController,
                  hintText: _getEmailHint(),
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (val) => FormValidators.validateEmailForRole(val ?? '', _selectedRole),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Text(
                    _getEmailHelperText(),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),

                // PHONE
                AppTextField(
                  controller: _phoneController,
                  hintText: '10-digit Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  validator: (val) => FormValidators.validatePhone(val ?? ''),
                ),
                const SizedBox(height: 14),

                // ROLL NUMBER (FOR STUDENT ONLY)
                if (_selectedRole == 'Student') ...[
                  AppTextField(
                    controller: _rollNumberController,
                    hintText: 'Roll Number (e.g. CB.EN.U4CSE21001)',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    validator: (val) => FormValidators.validateRollNumber(val ?? ''),
                  ),
                  const SizedBox(height: 14),
                ],

                // PASSWORD
                AppTextField(
                  controller: _passwordController,
                  hintText: 'Password (min 6 chars, letters & numbers)',
                  isPassword: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) => FormValidators.validatePassword(val ?? ''),
                ),
                const SizedBox(height: 14),

                // CONFIRM PASSWORD
                AppTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  isPassword: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Please confirm your password' : null,
                ),
                const SizedBox(height: 24),

                // SIGNUP BUTTON
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : AppButton(
                        text: 'Create $_selectedRole Account',
                        onPressed: _signup,
                      ),
                const SizedBox(height: 24),

                // BACK TO LOGIN
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
