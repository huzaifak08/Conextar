import 'package:conextar/clients/api_client.dart';
import 'package:conextar/models/api_response.dart';
import 'package:conextar/models/roundtable_model.dart';
import 'package:dio/dio.dart';

class RoundtableService {
  Future<ApiResponse<RoundtableModel>> create(String name) async {
    try {
      final Response response = await DioApiClient.postRequest(
        "/api/v1/roundtable/create",
        data: {"name": name},
      );
      final body = response.data;

      if (body != null && body['roundtable'] != null) {
        return ApiResponse<RoundtableModel>.success(
          body['message'] ?? "Roundtable successfully established.",
          RoundtableModel.fromMap(body['roundtable']),
        );
      }
      return ApiResponse.error(
        "Failed to parse roundtable registration payload.",
      );
    } on ContextarException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error(
        "Roundtable creation network runtime failure: $e",
      );
    }
  }

  Future<ApiResponse<RoundtableModel>> joinWithCode(String code) async {
    try {
      final Response response = await DioApiClient.postRequest(
        "/api/v1/roundtable/join",
        data: {"code": code},
      );
      final body = response.data;

      if (body != null && body['roundtable'] != null) {
        return ApiResponse<RoundtableModel>.success(
          body['message'] ?? "Successfully registered access to roundtable.",
          RoundtableModel.fromMap(body['roundtable']),
        );
      }
      return ApiResponse.error("Failed to parse joining metadata sequence.");
    } on ContextarException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error("Join roundtable request system failure: $e");
    }
  }

  Future<ApiResponse<RoundtableModel>> updateRoundtable({
    required String id,
    String? name,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (status != null) updateData['status'] = status;

      // Axios/Dio handle body payloads cleanly over custom standard PUT configurations too
      final Response response = await DioApiClient.postRequest(
        "/api/v1/roundtable/update/$id",
        data: updateData,
        options: Options(method: 'PUT'),
      );
      final body = response.data;

      if (body != null && body['roundtable'] != null) {
        return ApiResponse<RoundtableModel>.success(
          body['message'] ?? "Roundtable parameters updated successfully.",
          RoundtableModel.fromMap(body['roundtable']),
        );
      }
      return ApiResponse.error(
        "Failed to serialize modified settings context.",
      );
    } on ContextarException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error("Update parameters pipeline exception: $e");
    }
  }

  Future<ApiResponse<void>> deleteRoundtable(String id) async {
    try {
      final Response response = await DioApiClient.deleteRequest(
        "/api/v1/roundtable/delete/$id",
      );
      final body = response.data;

      return ApiResponse<void>(
        status: true,
        message:
            body['message'] ?? "Roundtable successfully dropped from indexing.",
        data: null,
      );
    } on ContextarException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error(
        "Purge operations execution roadblock encountered: $e",
      );
    }
  }

  Future<ApiResponse<void>> leaveRoundtable(String id) async {
    try {
      final Response response = await DioApiClient.patchRequest(
        "/api/v1/roundtable/leave/$id",
      );
      final body = response.data;

      return ApiResponse<void>(
        status: true,
        message: body['message'] ?? "Successfully left the roundtable.",
        data: null,
      );
    } on ContextarException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error("Participation extraction routine failure: $e");
    }
  }

  Future<ApiResponse<List<RoundtableModel>>> getMyRoundtables() async {
    try {
      final Response response = await DioApiClient.getRequest(
        "/api/v1/roundtable/my-feeds",
      );
      final body = response.data;

      if (body != null && body['roundtables'] != null) {
        final List<RoundtableModel> activeSpaces = List<RoundtableModel>.from(
          (body['roundtables'] as List).map(
            (element) =>
                RoundtableModel.fromMap(element as Map<String, dynamic>),
          ),
        );

        return ApiResponse<List<RoundtableModel>>.success(
          "User joined spaces parsed successfully.",
          activeSpaces,
        );
      }
      return ApiResponse.error(
        "Missing valid roundtables index container nodes.",
      );
    } on ContextarException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error(
        "Failed to parse personal joined rooms index arrays: $e",
      );
    }
  }
}
