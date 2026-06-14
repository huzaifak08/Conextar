import 'dart:async';
import 'package:conextar/components/custom_button.dart';
import 'package:conextar/constants/theme.dart';
import 'package:conextar/providers/app_provider_container.dart';
import 'package:conextar/providers/current_user/current_user_provider.dart';
import 'package:conextar/services/auth_service.dart';
import 'package:conextar/models/api_response.dart';
import 'package:conextar/models/user_model.dart';
import 'package:conextar/views/roundtable/roundtable_view.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class VerifyEmailView extends StatefulWidget {
  final String
  email; // Pass user's destination email address from previous view state

  const VerifyEmailView({super.key, required this.email});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  // Timer Properties
  Timer? _countdownTimer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  bool _isLoading = false;
  bool _isButtonActive = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _otpController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    // Enable submit button once a full 6-digit code has been populated
    final bool isComplete = _otpController.text.length == 6;
    if (isComplete != _isButtonActive) {
      setState(() => _isButtonActive = isComplete);
    }
  }

  void _startCountdown() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
          _countdownTimer?.cancel();
        });
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  // =========================================================================
  // EXECUTE OTP SUBMISSION
  // =========================================================================
  void _handleSubmitOtp() async {
    _otpFocusNode.unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      ApiResponse response = await AppProviderContainer.instance
          .read(currentUserProvider.notifier)
          .verifyEmailOtp(widget.email, _otpController.text);

      setState(() => _isLoading = false);

      if (response.status) {
        _showNotification(message: response.message, isError: false);

        // Extract session profile mappings safely
        UserModel? user = response.data;
        debugPrint("Session initialized for verified account: ${user?.name}");

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RoundtableView()),
          (route) => false,
        );
      } else {
        _showNotification(message: response.message, isError: true);
      }
    }
  }

  // =========================================================================
  // EXECUTE RESEND CODE CHALLENGE
  // =========================================================================
  void _handleResendCode() async {
    if (!_canResend) return;

    _showNotification(
      message: "Requesting a fresh verification token...",
      isError: false,
    );

    ApiResponse response = await _authService.resendOtp(email: widget.email);

    if (response.status) {
      _showNotification(message: response.message, isError: false);
      _startCountdown(); // Restart the 1-minute tracking interval block
    } else {
      _showNotification(message: response.message, isError: true);
    }
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
    _countdownTimer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 PINPUT CUSTOM MODERN CYBER-DARK HUD THEME DEFINITIONS
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 52,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: ContextarTheme.darkSlateGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ContextarTheme.darkSlateGreen, width: 1.5),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: ContextarTheme.neonCyan, width: 1.5),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: ContextarTheme.darkSlateGreen.withOpacity(0.4),
        border: Border.all(
          color: ContextarTheme.mutedTextCyan.withOpacity(0.6),
          width: 1.5,
        ),
      ),
    );

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
                    'VERIFY EMAIL',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: ContextarTheme.mutedTextCyan,
                        fontSize: 14,
                        fontFamily: 'DMSans',
                      ),
                      children: [
                        const TextSpan(
                          text:
                              "Input the 6-digit security sequence code sent to ",
                        ),
                        TextSpan(
                          text: widget.email,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 2. High-Tech Pinput Container Field
                  Center(
                    child: Pinput(
                      length: 6,
                      controller: _otpController,
                      focusNode: _otpFocusNode,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      keyboardType: TextInputType.number,
                      hapticFeedbackType: HapticFeedbackType.mediumImpact,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Please populate the full security clearance code';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. User Alert Info regarding Spam Folders
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffF04848).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xffF04848).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xffF04848),
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Can't locate the challenge code? Please look through your email account's junk/spam directory folder.",
                            style: TextStyle(
                              color: ContextarTheme.mutedTextCyan,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 4. Action Verification Button
                  CustomButton(
                    text: 'VERIFY ACCOUNT KEY',
                    isLoading: _isLoading,
                    onPressed: _isButtonActive ? _handleSubmitOtp : null,
                  ),
                  const SizedBox(height: 32),

                  // 5. Dynamic Countdown Clock UI Section
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_canResend)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.history,
                                color: ContextarTheme.mutedTextCyan,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Resend request unlocks in: 00:${_secondsRemaining.toString().padLeft(2, '0')}",
                                style: const TextStyle(
                                  color: ContextarTheme.mutedTextCyan,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        if (_canResend)
                          TextButton(
                            onPressed: _handleResendCode,
                            style: TextButton.styleFrom(
                              foregroundColor: ContextarTheme.neonCyan,
                            ),
                            child: const Text(
                              "RESEND SECURE CODE",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                      ],
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
