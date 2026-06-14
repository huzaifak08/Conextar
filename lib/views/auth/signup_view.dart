import 'package:conextar/components/custom_button.dart';
import 'package:conextar/components/custom_text_field.dart';
import 'package:conextar/constants/theme.dart';
import 'package:conextar/services/auth_service.dart';
import 'package:conextar/models/api_response.dart';
import 'package:conextar/views/auth/verify_email_view.dart';
import 'package:flutter/material.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus Nodes
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _isButtonActive = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateButtonState);
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _confirmPasswordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final bool isFormFilled =
        _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty;

    if (isFormFilled != _isButtonActive) {
      setState(() => _isButtonActive = isFormFilled);
    }
  }

  void _handleSignup() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      ApiResponse response = await _authService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (response.status) {
        // 🟢 SUCCESS: Account Initiated!
        _showNotification(message: response.message, isError: false);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VerifyEmailView(email: _emailController.text),
          ),
        );
      } else {
        // 🔴 ALL BACKEND ERRORS HANDLED HERE CLEANLY WITHOUT EXCEPTIONS CAUSING CRASHES
        // Shows exact messages like: "An account with this email address already exists."
        _showNotification(message: response.message, isError: true);
      }
    }
  }

  // =========================================================================
  // HANDLE SIGN IN TEXT LINK TAP
  // =========================================================================
  void _handleSignInTap() {
    if (Navigator.of(context).canPop()) {
      // If the user came to this view from the Login screen, simply pop back to it
      Navigator.of(context).pop();
    } else {
      // Fallback: If SignupView was opened directly or as root, push the LoginView explicitly
      // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginView()));
    }
  }

  /// Clean notification banner constructor matching our dark theme aesthetic
  void _showNotification({required String message, required bool isError}) {
    ScaffoldMessenger.of(
      context,
    ).clearSnackBars(); // Instantly clears lingering popups
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xffF04848)
            : ContextarTheme.neonCyan,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: ContextarTheme.buildBackgroundGradient(),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Header Block
                  Text(
                    'CREATE ACCOUNT',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Initialize your secure profile credentials.',
                    style: TextStyle(
                      color: ContextarTheme.mutedTextCyan,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 1. Name Field
                  CustomTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    nextFocusNode: _emailFocus,
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 2. Email Field
                  CustomTextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    nextFocusNode: _passwordFocus,
                    labelText: 'Email Address',
                    hintText: 'user@contextar.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Please enter a valid email format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 3. Password Field
                  CustomTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    nextFocusNode: _confirmPasswordFocus,
                    labelText: 'Secure Password',
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please establish a security password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 4. Confirm Password Field
                  CustomTextField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocus,
                    labelText: 'Confirm Password',
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_reset_outlined,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please re-enter your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // 5. Action Button
                  CustomButton(
                    text: 'INITIALIZE CORE PROFILE',
                    isLoading: _isLoading,
                    onPressed: _isButtonActive ? _handleSignup : null,
                  ),
                  const SizedBox(height: 24),

                  // 6. Linked Sign-In Redirection
                  Center(
                    child: GestureDetector(
                      onTap:
                          _handleSignInTap, // Wired tap event handler directly
                      behavior: HitTestBehavior
                          .opaque, // Expands hit detection area for cleaner taps
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'DMSans',
                            ),
                            children: [
                              TextSpan(
                                text: 'Already registered? ',
                                style: TextStyle(
                                  color: ContextarTheme.mutedTextCyan,
                                ),
                              ),
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  color: ContextarTheme.neonCyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
