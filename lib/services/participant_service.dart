import 'package:conextar/clients/api_client.dart';
import 'package:conextar/models/api_response.dart';
import 'package:conextar/models/roundtable_participant_model.dart';
import 'package:dio/dio.dart';

class ParticipantService {
  Future<ApiResponse<List<RoundtableParticipantModel>>>
  getRoundtableParticipants(String roundtableId) async {
    try {
      final Response response = await DioApiClient.getRequest(
        "/api/v1/participant/roundtable/$roundtableId",
      );
      final body = response.data;

      if (body != null && body['participants'] != null) {
        final List<RoundtableParticipantModel> list =
            List<RoundtableParticipantModel>.from(
              (body['participants'] as List).map(
                (element) => RoundtableParticipantModel.fromMap(
                  element as Map<String, dynamic>,
                ),
              ),
            );

        return ApiResponse<List<RoundtableParticipantModel>>.success(
          body['message'] ?? "Participants loaded successfully.",
          list,
        );
      }
      return ApiResponse.error("Failed to parse participants array payload.");
    } on ContextarException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error(
        "Participants index synchronization roadblock: $e",
      );
    }
  }

  Future<ApiResponse<RoundtableParticipantModel>> getParticipantDetails({
    required String roundtableId,
    required String userId,
  }) async {
    try {
      final Response response = await DioApiClient.getRequest(
        "/api/v1/participant/roundtable/$roundtableId/user/$userId",
      );
      final body = response.data;

      if (body != null && body['participant'] != null) {
        return ApiResponse<RoundtableParticipantModel>.success(
          body['message'] ?? "Participant details retrieved successfully.",
          RoundtableParticipantModel.fromMap(body['participant']),
        );
      }
      return ApiResponse.error("Failed to parse participant detail records.");
    } on ContextarException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error("Participant profile verification failure: $e");
    }
  }
}
