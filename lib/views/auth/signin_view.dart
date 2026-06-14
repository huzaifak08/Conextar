import 'package:conextar/components/custom_button.dart';
import 'package:conextar/components/custom_text_field.dart';
import 'package:conextar/constants/theme.dart';
import 'package:conextar/providers/app_provider_container.dart';
import 'package:conextar/providers/current_user/current_user_provider.dart';
import 'package:conextar/services/auth_service.dart';
import 'package:conextar/models/api_response.dart';
import 'package:conextar/models/user_model.dart';
import 'package:conextar/views/auth/signup_view.dart';
import 'package:conextar/views/auth/verify_email_view.dart';
import 'package:conextar/views/roundtable/roundtable_view.dart';
import 'package:flutter/material.dart';

class SigninView extends StatefulWidget {
  const SigninView({super.key});

  @override
  State<SigninView> createState() => _SigninViewState();
}

class _SigninViewState extends State<SigninView> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Focus Nodes
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isButtonActive = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final bool isFormFilled =
        _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;

    if (isFormFilled != _isButtonActive) {
      setState(() => _isButtonActive = isFormFilled);
    }
  }

  // =========================================================================
  // HANDLE SECURE SIGN IN SUBMIT
  // =========================================================================
  void _handleSignin() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 1. Fire your login call pipeline

      ApiResponse response = await AppProviderContainer.instance
          .read(currentUserProvider.notifier)
          .signInUser(_emailController.text, _passwordController.text);

      if (response.status) {
        // Safe cast to get your logged-in profile data parameters
        final UserModel? user = response.data as UserModel?;

        // 2. CHECK VERIFICATION STATE IDENTITY MATCHING
        if (user != null && !user.isVerified) {
          // Trigger a fresh verification code challenge to their inbox silently
          await _authService.resendOtp(email: user.email);

          setState(() => _isLoading = false);

          _showNotification(
            message:
                "Account unverified. A security key has been dispatched to your inbox.",
            isError: true,
          );

          // Route to verification view, passing their email configuration string down
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => VerifyEmailView(email: user.email),
              ),
            );
          }
        } else {
          // 🟢 SUCCESS: Fully verified user, unlock dashboard access
          setState(() => _isLoading = false);
          _showNotification(message: response.message, isError: false);

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const RoundtableView()),
            );
          }
        }
      } else {
        // 🔴 FAIL: 401 Unauthorized, 404 Not Found, etc.
        setState(() => _isLoading = false);
        _showNotification(message: response.message, isError: true);
      }
    }
  }

  // =========================================================================
  // REDIRECT TO SIGNUP
  // =========================================================================
  void _handleRegisterTap() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SignupView()));
  }

  void _showNotification({required String message, required bool isError}) {
    ScaffoldMessenger.of(context).clearSnackBars();
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
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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

                  // Header Layout
                  Text(
                    'WELCOME BACK',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Unlock your credentials to initialize system sync.',
                    style: TextStyle(
                      color: ContextarTheme.mutedTextCyan,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 1. Email Field
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

                  // 2. Password Field
                  CustomTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    labelText: 'Account Password',
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // 3. Action Submission Button
                  CustomButton(
                    text: 'ACCESS UNLOCKED',
                    isLoading: _isLoading,
                    onPressed: _isButtonActive ? _handleSignin : null,
                  ),
                  const SizedBox(height: 24),

                  // 4. Linked Sign-Up Redirection
                  Center(
                    child: GestureDetector(
                      onTap: _handleRegisterTap,
                      behavior: HitTestBehavior.opaque,
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
                                text: "Don't have an account? ",
                                style: TextStyle(
                                  color: ContextarTheme.mutedTextCyan,
                                ),
                              ),
                              TextSpan(
                                text: 'Sign Up',
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
