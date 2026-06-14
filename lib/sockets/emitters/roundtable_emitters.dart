import 'package:conextar/sockets/init.dart';

class RoundtableEmitters {
  final _socket = SocketService().socket;

  void enterRoundtable({required String roundtableId, required String userId}) {
    _socket.emit('enter_roundtable', {
      'roundtableId': roundtableId,
      'userId': userId,
    });
  }

  void claimSofa({
    required String roundtableId,
    required String userId,
    required int sofaIndex,
  }) {
    _socket.emit('claim_sofa', {
      'roundtableId': roundtableId,
      'userId': userId,
      'sofaIndex': sofaIndex,
    });
  }

  void leaveSofa({required String roundtableId, required String userId}) {
    _socket.emit('leave_sofa', {
      'roundtableId': roundtableId,
      'userId': userId,
    });
  }

  void leaveRoundtableEngine() {
    _socket.emit('leave_roundtable_view');
  }
}
