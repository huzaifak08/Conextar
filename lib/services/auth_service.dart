import 'package:conextar/clients/api_client.dart';
import 'package:conextar/constants/sp_helper.dart';
import 'package:conextar/models/api_response.dart';
import 'package:conextar/models/user_model.dart'; // Make sure this points to your refactored UserModel
import 'package:dio/dio.dart';

class AuthService {
  Future<ApiResponse<String>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final Response response = await DioApiClient.postRequest(
        "/api/v1/auth/register",
        data: {
          "name": name.trim(),
          "email": email.trim(),
          "password": password,
        },
        logs: const LogOptions(responseData: true),
      );

      final body = response.data;

      // Backend returns: status, message, userId
      return ApiResponse<String>(
        status: true,
        message:
            body['message'] ??
            "Account initiated. Secure code dispatched to inbox.",
        data: body['userId']
            ?.toString(), // Passes the absolute user ID string to the UI
      );
    } on ContextarException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error("Registration structural error: $e");
    }
  }

  Future<ApiResponse<UserModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final Response response = await DioApiClient.postRequest(
        "/api/v1/auth/signin",
        data: {"email": email.trim(), "password": password},
        logs: const LogOptions(responseData: true),
      );

      final body = response.data;

      SpHelper.addOrUpdateAccessToken(body['accessToken']);
      SpHelper.addOrUpdateRefreshToken(body['refreshToken']);

      final token = await SpHelper.getRefreshToken();
      print("Refresh Token: $token");

      // Parse the root 'user' JSON object safely using our modern model fromMap setup
      final UserModel loggedInUser = UserModel.fromMap(body['user'] ?? {});

      return ApiResponse<UserModel>(
        status: true,
        message: body['message'] ?? "Access unlocked successfully.",
        data:
            loggedInUser, // Delivers a strongly-typed model straight to your controllers
      );
    } on ContextarException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error("Login mapping failure: $e");
    }
  }

  Future<ApiResponse<UserModel>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final Response response = await DioApiClient.postRequest(
        "/api/v1/auth/verify-email",
        data: {
          "email": email.trim(),
          "code": otp.trim(), // 🟢 FIXED: Changed key from 'otp' to 'code'
        },
        logs: const LogOptions(requestData: true, responseData: true),
      );

      final body = response.data;
      SpHelper.addOrUpdateAccessToken(body['accessToken']);
      SpHelper.addOrUpdateRefreshToken(body['refreshToken']);

      final UserModel verifiedUser = UserModel.fromMap(body['user'] ?? {});

      return ApiResponse<UserModel>(
        status: true,
        message: body['message'] ?? "Verification success.",
        data: verifiedUser,
      );
    } on ContextarException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error("Verification processing failure: $e");
    }
  }

  Future<ApiResponse<void>> resendOtp({required String email}) async {
    try {
      final Response response = await DioApiClient.postRequest(
        "/api/v1/auth/resend-code", // Point this to your verification challenge route
        data: {"email": email.trim()},
      );

      final body = response.data;

      return ApiResponse<void>(
        status: true,
        message:
            body['message'] ??
            "A fresh verification challenge code has been dispatched to your inbox.",
        data: null,
      );
    } on ContextarException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error("Failed to resend validation context: $e");
    }
  }

  Future<ApiResponse<UserModel>> maintainSession(String refreshToken) async {
    try {
      final Response response = await DioApiClient.postRequest(
        "/api/v1/auth/refresh-session",
        data: {"refreshToken": refreshToken},
      );

      final body = response.data;

      SpHelper.addOrUpdateAccessToken(body['accessToken']);
      SpHelper.addOrUpdateRefreshToken(body['refreshToken']);

      final UserModel activeUser = UserModel.fromMap(body['user'] ?? {});

      return ApiResponse<UserModel>(
        status: true,
        message: "Session context synchronized smoothly.",
        data: activeUser,
      );
    } on ContextarException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error("Session re-establishment failed: $e");
    }
  }

  Future<ApiResponse<void>> logout() async {
    try {
      final refreshToken = await SpHelper.getRefreshToken();

      final Response response = await DioApiClient.postRequest(
        "/api/v1/auth/logout",
        data: {"refreshToken": refreshToken},
      );
      final body = response.data;

      return ApiResponse<void>(
        status: true,
        message: body['message'] ?? "Session dropped cleanly.",
        data: null,
      );
    } on ContextarException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error("Logout execution execution failure: $e");
    }
  }

  Future<ApiResponse<void>> deleteAccount() async {
    try {
      final Response response = await DioApiClient.deleteRequest(
        "/api/v1/auth/delete",
      );
      final body = response.data;

      return ApiResponse<void>(
        status: true,
        message:
            body['message'] ??
            "Profile completely purged from systems database.",
        data: null,
      );
    } on ContextarException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error(
        "Purge operations crashed on runtime application: $e",
      );
    }
  }
}
