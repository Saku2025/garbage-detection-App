import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      String message = e.toString().replaceFirst('Exception: ', '');

      if (message.toLowerCase().contains('email not confirmed')) {
        message = 'Please verify your email before signing in.';
      } else if (message.toLowerCase().contains('invalid login credentials')) {
        message = 'Incorrect email or password.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // OPEN SIGNUP
  // ============================================================

  void _openSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupScreen()),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 50, 24, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // APP ICON
                // ==================================================

                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      Icons.eco_outlined,
                      size: 52,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // APP NAME
                // ==================================================
                Center(
                  child: Text(
                    'Garbage Detection',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ==================================================
                // APP DESCRIPTION
                // ==================================================
                Center(
                  child: Text(
                    'Keep your surroundings clean and green',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(height: 42),

                // ==================================================
                // WELCOME
                // ==================================================
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // EMAIL LABEL
                // ==================================================
                _buildLabel('Email', colorScheme),

                const SizedBox(height: 8),

                // ==================================================
                // EMAIL FIELD
                // ==================================================
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    hint: 'Enter your email',
                    icon: Icons.email_outlined,
                    colorScheme: colorScheme,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ==================================================
                // PASSWORD LABEL
                // ==================================================
                _buildLabel('Password', colorScheme),

                const SizedBox(height: 8),

                // ==================================================
                // PASSWORD FIELD
                // ==================================================
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration:
                      _inputDecoration(
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                        colorScheme: colorScheme,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }

                    return null;
                  },
                  onFieldSubmitted: (_) => _login(),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // SIGN IN BUTTON
                // ==================================================
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      disabledBackgroundColor: colorScheme.primary.withValues(
                        alpha: 0.45,
                      ),
                      disabledForegroundColor: colorScheme.onPrimary.withValues(
                        alpha: 0.75,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 22),

                // ==================================================
                // SIGN UP
                // ==================================================
                Center(
                  child: TextButton(
                    onPressed: _openSignup,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                    ),
                    child: Text(
                      "Don't have an account? Create Account",
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(String text, ColorScheme colorScheme) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),

      prefixIcon: Icon(icon, color: colorScheme.primary),

      filled: true,

      fillColor: colorScheme.surface,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
    );
  }
}
