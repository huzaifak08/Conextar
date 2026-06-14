import 'package:conextar/clients/api_client.dart';
import 'package:conextar/models/api_response.dart';
import 'package:dio/dio.dart';

class UserService {
  Future<ApiResponse<void>> changePassword(
    String oldPass,
    String newPass,
  ) async {
    try {
      final Response response = await DioApiClient.patchRequest(
        "/api/v1/user/change-password",
        data: {"oldPassword": oldPass, "newPassword": newPass},
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
}
