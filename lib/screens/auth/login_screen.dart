import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../home/main_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? initialIdentity;

  const LoginScreen({
    super.key,
    this.initialIdentity,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _identityController;
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = true;
  bool _hasLoadedSavedLogin = false;
  String _selectedRole = 'Student';

  final List<String> _roles = ['Student', 'Faculty', 'Visitor'];

  @override
  void initState() {
    super.initState();
    _identityController = TextEditingController(text: widget.initialIdentity ?? '');
    _identityController.addListener(_onIdentityChanged);
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final saved = await AuthService.getSavedLoginPreferences();
      if (!mounted) return;
      final savedIdentity = saved['identity'] as String? ?? '';
      final savedRole = saved['role'] as String? ?? 'Student';
      final rememberMe = saved['rememberMe'] as bool? ?? true;

      setState(() {
        _rememberMe = rememberMe;
        if (widget.initialIdentity == null || widget.initialIdentity!.isEmpty) {
          if (savedIdentity.isNotEmpty) {
            _identityController.text = savedIdentity;
            _hasLoadedSavedLogin = true;
          }
        }
        if (_roles.contains(savedRole)) {
          _selectedRole = savedRole;
        }
      });
    } catch (_) {}
  }

  void _onIdentityChanged() {
    final text = _identityController.text.trim().toLowerCase();
    if (text.isEmpty) return;

    if (text.contains('@cb.amrita.edu') || (text.contains('@amrita.edu') && !text.contains('student'))) {
      if (_selectedRole != 'Faculty') {
        setState(() => _selectedRole = 'Faculty');
      }
    } else if (text.contains('student') || text.startsWith('cb.sc.') || text.startsWith('cb.en.')) {
      if (_selectedRole != 'Student') {
        setState(() => _selectedRole = 'Student');
      }
    } else if (text.contains('@gmail.com') || text.startsWith('vis')) {
      if (_selectedRole != 'Visitor') {
        setState(() => _selectedRole = 'Visitor');
      }
    }
  }

  @override
  void dispose() {
    _identityController.removeListener(_onIdentityChanged);
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getIdentityHint() {
    switch (_selectedRole) {
      case 'Visitor':
        return 'user@gmail.com, 10-digit phone, or Visitor ID';
      case 'Faculty':
        return 'faculty@cb.amrita.edu, phone, or Emp ID';
      case 'Student':
      default:
        return 'Email, Roll No (e.g. CB.SC.U4...), or phone';
    }
  }

  String _getIdentityHelperText() {
    switch (_selectedRole) {
      case 'Visitor':
        return 'Requires @gmail.com, phone, or Visitor ID';
      case 'Faculty':
        return 'Requires @cb.amrita.edu, phone, or Emp ID';
      case 'Student':
      default:
        return 'Use student email, Roll Number, or phone';
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final identity = _identityController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthResult result = await _authService.signInUser(
        identity: identity,
        password: password,
        role: _selectedRole,
      );

      if (!mounted) return;

      if (result.success) {
        // Save persistent login preferences so user never loses credentials
        await AuthService.saveLoginPreferences(
          identity: identity,
          role: _selectedRole,
          rememberMe: _rememberMe,
        );
        await AuthService.setOnboardingCompleted();

        if (!mounted) return;

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
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      } else {
        // Automatically switch role tab if backend indicates account belongs to another role
        if (result.message.contains('registered as Faculty')) {
          setState(() => _selectedRole = 'Faculty');
        } else if (result.message.contains('registered as Student')) {
          setState(() => _selectedRole = 'Student');
        } else if (result.message.contains('registered as Visitor')) {
          setState(() => _selectedRole = 'Visitor');
        }

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
            content: Text('Authentication error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      appBar: AppBar(backgroundColor: AppColors.white, elevation: 0),
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
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to access your Campus Connect account',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 24),

                // SAVED ACCOUNT BANNER (IF LOADED)
                if (_hasLoadedSavedLogin && _identityController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bookmark_added_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Saved account pre-filled',
                              style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _identityController.clear();
                                _passwordController.clear();
                                _hasLoadedSavedLogin = false;
                              });
                              AuthService.saveLoginPreferences(identity: '', role: 'Student', rememberMe: false);
                            },
                            child: const Text(
                              'Clear',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

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
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
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

                // IDENTITY INPUT
                AppTextField(
                  controller: _identityController,
                  hintText: _getIdentityHint(),
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (val) => FormValidators.validateLoginIdentityForRole(val ?? '', _selectedRole),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Text(
                    _getIdentityHelperText(),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),

                // PASSWORD INPUT
                AppTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  isPassword: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Password is required' : null,
                ),
                const SizedBox(height: 12),

                // REMEMBER ME & FORGOT PASSWORD ROW
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() => _rememberMe = val ?? true);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _rememberMe = !_rememberMe),
                          child: const Text(
                            'Remember Me',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contact campus IT desk for password reset assistance.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // LOGIN BUTTON
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : AppButton(
                        text: 'Login as $_selectedRole',
                        onPressed: _login,
                      ),
                const SizedBox(height: 32),

                // SIGNUP LINK
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        );
                      },
                      child: const Text(
                        'Sign Up',
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
