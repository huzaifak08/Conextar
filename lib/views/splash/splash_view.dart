import 'dart:async';
import 'package:conextar/constants/sp_helper.dart';
import 'package:conextar/constants/theme.dart';
import 'package:conextar/providers/app_provider_container.dart';
import 'package:conextar/providers/current_user/current_user_provider.dart';
import 'package:conextar/services/auth_service.dart';
import 'package:conextar/views/auth/signin_view.dart';
import 'package:conextar/views/auth/verify_email_view.dart';
import 'package:conextar/views/roundtable/roundtable_view.dart';
import 'package:flutter/material.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _initializeSessionAndRoute();
  }

  // =========================================================================
  // PARALLEL TIMING & SESSION ROUTING LOGIC
  // =========================================================================
  void _initializeSessionAndRoute() async {
    // 1. Kickstart your 3-second visual branding timer window
    final stopwatchFuture = Future.delayed(const Duration(seconds: 3));

    Widget destinationView = const SigninView();

    try {
      // 2. Read local token context from your SharedPreferences storage layer
      final String? token = await SpHelper.getRefreshToken();

      if (token != null && token.isNotEmpty) {
        final user = await AppProviderContainer.instance.read(
          currentUserProvider.future,
        );

        if (user != null) {
          if (user.isVerified) {
            destinationView = RoundtableView();
          } else if (!user.isVerified) {
            await AuthService().resendOtp(email: user.email);
            destinationView = VerifyEmailView(email: user.email);
          }
        } else {
          SpHelper.clearAll();
          destinationView = SigninView();
        }
      }
    } catch (e) {
      debugPrint("Runtime structural session parsing error caught: $e");
    }

    // 5. Wait out whatever is remaining of the 3-second stopwatch animation window
    await stopwatchFuture;

    // 6. Fire your view transitions safely
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => destinationView),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: ContextarTheme.buildBackgroundGradient(),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, opacityValue, child) {
                  return Opacity(
                    opacity: opacityValue,
                    child: Transform.scale(
                      scale: 0.95 + (0.05 * opacityValue),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CONTEXTAR',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8.0,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 80,
                      height: 2,
                      decoration: BoxDecoration(
                        color: ContextarTheme.neonCyan,
                        boxShadow: [
                          BoxShadow(
                            color: ContextarTheme.neonCyan.withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
