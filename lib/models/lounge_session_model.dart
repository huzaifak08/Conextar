import 'package:conextar/models/lounge_state_model.dart';

class LoungeSessionState {
  final LoungeStateModel? matrix; // Realtime seat positions from Socket.io
  final int? myOccupiedSofaIndex; // Index if user is sitting on a sofa
  final bool isConnectingAudio; // Handshake status indicator flag
  final bool isMuted; // Microphone status
  final bool isSpeakerOn; // Loudspeaker vs. earpiece tracking
  final Map<String, bool>
  activeSpeakers; // Currently talking users (userId -> talking)

  LoungeSessionState({
    this.matrix,
    this.myOccupiedSofaIndex,
    this.isConnectingAudio = false,
    this.isMuted = false,
    this.isSpeakerOn = true,
    this.activeSpeakers = const {},
  });

  LoungeSessionState copyWith({
    LoungeStateModel? matrix,
    int? myOccupiedSofaIndex,
    bool? isConnectingAudio,
    bool? isMuted,
    bool? isSpeakerOn,
    Map<String, bool>? activeSpeakers,
  }) {
    return LoungeSessionState(
      matrix: matrix ?? this.matrix,
      myOccupiedSofaIndex: myOccupiedSofaIndex ?? this.myOccupiedSofaIndex,
      isConnectingAudio: isConnectingAudio ?? this.isConnectingAudio,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      activeSpeakers: activeSpeakers ?? this.activeSpeakers,
    );
  }
}
