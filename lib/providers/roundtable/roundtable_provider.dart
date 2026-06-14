import 'package:conextar/models/api_response.dart';
import 'package:conextar/models/roundtable_model.dart';
import 'package:conextar/services/roundtable_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'roundtable_provider.g.dart';

@riverpod
class RoundtableNotifier extends _$RoundtableNotifier {
  final RoundtableService _roundtableService = RoundtableService();

  @override
  FutureOr<List<RoundtableModel>> build() async {
    final response = await _roundtableService.getMyRoundtables();
    if (response.status && response.data != null) {
      return response.data!;
    }
    return [];
  }

  Future<ApiResponse<RoundtableModel>> createRoundtable(String name) async {
    final response = await _roundtableService.create(name);

    if (response.status && response.data != null) {
      final currentList = state.value ?? [];
      state = AsyncData([response.data!, ...currentList]);
    }

    return response;
  }

  Future<ApiResponse<RoundtableModel>> joinWithCode(String code) async {
    final response = await _roundtableService.joinWithCode(code);

    if (response.status && response.data != null) {
      final currentList = state.value ?? [];

      final alreadyExists = currentList.any(
        (element) => element.id == response.data!.id,
      );
      if (!alreadyExists) {
        state = AsyncData([response.data!, ...currentList]);
      }
    }

    return response;
  }

  Future<ApiResponse<RoundtableModel>> updateRoundtableDetails({
    required String id,
    String? name,
    String? status,
  }) async {
    final response = await _roundtableService.updateRoundtable(
      id: id,
      name: name,
      status: status,
    );

    if (response.status && response.data != null) {
      final currentList = state.value ?? [];

      state = AsyncData(
        currentList
            .map((item) => item.id == id ? response.data! : item)
            .toList(),
      );
    }

    return response;
  }

  Future<ApiResponse<void>> deleteRoundtable(String id) async {
    final response = await _roundtableService.deleteRoundtable(id);

    if (response.status) {
      final currentList = state.value ?? [];
      state = AsyncData(currentList.where((item) => item.id != id).toList());
    }

    return response;
  }

  Future<ApiResponse<void>> leaveRoundtable(String id) async {
    final response = await _roundtableService.leaveRoundtable(id);

    if (response.status) {
      final currentList = state.value ?? [];
      state = AsyncData(currentList.where((item) => item.id != id).toList());
    }

    return response;
  }

  Future<ApiResponse<List<RoundtableModel>>> refreshRoundtables() async {
    state = const AsyncLoading();
    final response = await _roundtableService.getMyRoundtables();

    if (response.status && response.data != null) {
      state = AsyncData(response.data!);
    } else {
      state = AsyncError(response.message, StackTrace.current);
    }

    return response;
  }
}
