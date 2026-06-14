import 'package:conextar/constants/sp_helper.dart';
import 'package:conextar/models/api_response.dart';
import 'package:conextar/models/user_model.dart';
import 'package:conextar/services/auth_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_user_provider.g.dart';

@Riverpod(keepAlive: true)
class CurrentUserNotifier extends _$CurrentUserNotifier {
  final AuthService _authService = AuthService();

  @override
  FutureOr<UserModel?> build() async {
    // 1. Read persistent token to check if an active session profile exists
    final String? token = await SpHelper.getRefreshToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    // 2. Perform background synchronization validation via maintainSession
    final ApiResponse response = await _authService.maintainSession(token);
    if (response.status && response.data != null) {
      return response.data as UserModel;
    }

    // Fallback: Drop token and reset session if backend sync fails
    await SpHelper.clearAll();
    return null;
  }

  // =========================================================================
  // 1. SIGN IN FLOW MANAGEMENT
  // =========================================================================
  Future<ApiResponse> signInUser(String email, String password) async {
    ApiResponse response = await _authService.login(
      email: email,
      password: password,
    );

    if (response.status) {
      final UserModel? user = response.data as UserModel?;

      if (user != null) {
        // 🎯 FIX: Updates the global Riverpod state cleanly regardless of verification state.
        // If user is verified, this unlocks RoomsView immediately across the app footprint.
        // If unverified, it still holds the user data in memory so VerifyEmailView reads it.
        state = AsyncData(user);
      }
    }

    return response;
  }

  // =========================================================================
  // 2. VERIFY EMAIL OTP FLOW MANAGEMENT
  // =========================================================================
  Future<ApiResponse> verifyEmailOtp(String email, String otp) async {
    ApiResponse response = await _authService.verifyOtp(email: email, otp: otp);

    if (response.status) {
      final UserModel? verifiedUser = response.data as UserModel?;

      if (verifiedUser != null) {
        // 🎯 Update the global Riverpod state wrapper to the finalized, fully verified model
        state = AsyncData(verifiedUser);
      }
    }

    return response;
  }

  // =========================================================================
  // 3. LOGOUT UTILITY CLOSURE
  // =========================================================================
  Future<void> logoutUser() async {
    await _authService.logout();
    await SpHelper.clearAll();
    state = const AsyncData(
      null,
    ); // Resets global system states cleanly back to null baseline
  }
}
