import 'package:conextar/models/lounge_state_model.dart';
import 'package:conextar/sockets/init.dart';
import 'package:flutter/foundation.dart';

class RoundtableHandlers {
  final _socket = SocketService().socket;

  void listenToLoungeState(Function(LoungeStateModel) onUpdate) {
    _socket.on('roundtable_state_changed', (data) {
      try {
        if (data is Map) {
          final state = LoungeStateModel.fromMap(data as Map<String, dynamic>);
          onUpdate(state);
        }
      } catch (e) {
        debugPrint("❌ [Socket State Handler] Parsing crash: $e");
      }
    });
  }

  void listenToClaimSuccess(Function(int sofaIndex, String token) onSuccess) {
    _socket.on('sofa_claim_success', (data) {
      if (data is Map) {
        onSuccess(data['sofaIndex'] as int, data['token']?.toString() ?? '');
      }
    });
  }

  void listenToClaimRejected(Function(String reason) onRejected) {
    _socket.on('sofa_claim_rejected', (data) {
      if (data is Map && data['message'] != null) {
        onRejected(data['message'].toString());
      }
    });
  }

  void listenToSystemErrors(Function(String error) onError) {
    _socket.on('system_error', (data) {
      if (data is Map && data['message'] != null)
        onError(data['message'].toString());
    });
  }

  void clearAllRoomListeners() {
    _socket.off('roundtable_state_changed');
    _socket.off('sofa_claim_success');
    _socket.off('sofa_claim_rejected');
    _socket.off('system_error');
  }
}
