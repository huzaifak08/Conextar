import 'package:conextar/models/api_response.dart';
import 'package:conextar/models/roundtable_participant_model.dart';
import 'package:conextar/services/participant_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'roundtable_participant_provider.g.dart';

@riverpod
class RoundtableParticipantNotifier extends _$RoundtableParticipantNotifier {
  final ParticipantService _participantService = ParticipantService();

  @override
  FutureOr<List<RoundtableParticipantModel>> build(String roundtableId) async {
    final response = await _participantService.getRoundtableParticipants(
      roundtableId,
    );
    if (response.status && response.data != null) {
      return response.data!;
    }
    return [];
  }

  Future<ApiResponse<List<RoundtableParticipantModel>>>
  refreshParticipants() async {
    final response = await _participantService.getRoundtableParticipants(
      roundtableId,
    );

    if (response.status && response.data != null) {
      state = AsyncData(response.data!);
    } else {
      state = AsyncError(response.message, StackTrace.current);
    }

    return response;
  }

  Future<ApiResponse<RoundtableParticipantModel>> getSingleParticipantDetails(
    String userId,
  ) async {
    final response = await _participantService.getParticipantDetails(
      roundtableId: roundtableId,
      userId: userId,
    );

    if (response.status && response.data != null) {
      final currentList = state.value ?? [];

      final index = currentList.indexWhere(
        (element) => element.userId == userId,
      );
      if (index != -1) {
        final updatedList = List<RoundtableParticipantModel>.from(currentList);
        updatedList[index] = response.data!;
        state = AsyncData(updatedList);
      }
    }

    return response;
  }
}
