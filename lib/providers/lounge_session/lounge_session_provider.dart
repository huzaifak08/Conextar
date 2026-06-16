import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:conextar/models/lounge_session_model.dart';
import 'package:conextar/providers/current_user/current_user_provider.dart';
import 'package:conextar/sockets/emitters/roundtable_emitters.dart';
import 'package:conextar/sockets/handlers/roundtable_handlers.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

part 'lounge_session_provider.g.dart';

// 🎯 FIX: Kept as autoDispose (default behavior for @riverpod)
// so it handles memory cleanup when you leave the roundtable view
@riverpod
class LoungeSession extends _$LoungeSession {
  final _emitters = RoundtableEmitters();
  final _handlers = RoundtableHandlers();

  Room? _liveKitRoom;
  EventsListener<RoomEvent>? _liveKitListener;
  String? _activeRoundtableId;
  bool _isDisposed = false; // 🛡️ Safety Flag

  @override
  LoungeSessionState build() {
    // Automatically clean up channels when this provider is completely unobserved
    ref.onDispose(() {
      _isDisposed = true;
      _cleanupLiveKitHardware();
      _emitters.leaveRoundtableEngine();
      _handlers.clearAllRoomListeners();
    });

    return LoungeSessionState();
  }

  /// Initializes listening tunnels with backend sockets for a specified roundtable ID
  void initLoungePipeline(String roundtableId) {
    // 🎯 FIX: Clear any existing active listeners before initializing a new screen stance
    _handlers.clearAllRoomListeners();
    _activeRoundtableId = roundtableId;

    // 1. Sync backend socket room parameters down to state map
    _handlers.listenToLoungeState((updatedMatrix) {
      if (_isDisposed) return;

      final myId = ref.read(currentUserProvider).value?.id;
      final seat = updatedMatrix.sofas.indexWhere((s) => s.user?.id == myId);
      final myIndex = (seat != -1) ? updatedMatrix.sofas[seat].sofaIndex : null;

      state = state.copyWith(
        matrix: updatedMatrix,
        myOccupiedSofaIndex: myIndex,
      );
    });

    // 2. Map direct success triggers straight to the LiveKit configuration sequence
    _handlers.listenToClaimSuccess((sofaIndex, token) async {
      if (_isDisposed) return;
      state = state.copyWith(
        myOccupiedSofaIndex: sofaIndex,
        isConnectingAudio: true,
      );
      await _connectToLiveKit(token);
    });

    _handlers.listenToClaimRejected(
      (reason) => _showToast(reason, isError: true),
    );
    _handlers.listenToSystemErrors((err) => _showToast(err, isError: true));

    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      _emitters.enterRoundtable(roundtableId: roundtableId, userId: user.id);
    }
  }

  /// Core Sofa Tap Handler managing permission gating and socket submission
  Future<void> handleSofaTap(int index) async {
    final matrixState = state.matrix;
    final user = ref.read(currentUserProvider).value;
    if (user == null ||
        matrixState == null ||
        state.isConnectingAudio ||
        _activeRoundtableId == null ||
        _isDisposed)
      return;

    final targetSofa = matrixState.sofas.firstWhere(
      (s) => s.sofaIndex == index,
    );

    if (targetSofa.user != null) {
      if (targetSofa.user!.id == user.id) {
        await triggerHangup();
      } else {
        _showToast("CHANNEL SLOT OCCUPIED", isError: true);
      }
    } else {
      if (state.myOccupiedSofaIndex != null) {
        _showToast("VACATE CURRENT SOFA NODE FIRST", isError: true);
        return;
      }

      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }

      if (!status.isGranted) {
        _showToast("MICROPHONE ACCESS DENIED BY SYSTEM", isError: true);
        return;
      }

      _emitters.claimSofa(
        roundtableId: _activeRoundtableId!,
        userId: user.id,
        sofaIndex: index,
      );
    }
  }

  /// LiveKit WebRTC Core Connection Handler
  Future<void> _connectToLiveKit(String token) async {
    if (_activeRoundtableId == null || _isDisposed) return;

    try {
      _liveKitRoom = Room();

      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.defaultToSpeaker,
          avAudioSessionMode: AVAudioSessionMode.voiceChat,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.voiceCommunication,
          ),
          androidAudioFocusGainType:
              AndroidAudioFocusGainType.gainTransientMayDuck,
          androidWillPauseWhenDucked: false,
        ),
      );

      if (state.isSpeakerOn) {
        await session.setActive(true);
      }

      // const liveKitServerUrl = "ws://192.168.1.15:7880";
      const liveKitServerUrl = "ws://52.214.206.137:7880";

      await _liveKitRoom!
          .connect(
            liveKitServerUrl,
            token,
            roomOptions: const RoomOptions(
              defaultAudioPublishOptions: AudioPublishOptions(dtx: true),
            ),
          )
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () =>
                throw Exception("Internal signaling tunnel timeout reached."),
          );

      if (_isDisposed) {
        _cleanupLiveKitHardware();
        return;
      }

      await _liveKitRoom!.setSpeakerOn(state.isSpeakerOn);

      _liveKitListener = _liveKitRoom!.createListener();
      _liveKitListener!.on<ActiveSpeakersChangedEvent>((event) {
        if (_isDisposed) return;
        final Map<String, bool> speakers = {};
        for (var p in event.speakers) {
          speakers[p.identity] = true;
        }
        state = state.copyWith(activeSpeakers: speakers);
      });

      if (_liveKitRoom?.localParticipant != null) {
        await _liveKitRoom!.localParticipant!.setMicrophoneEnabled(
          !state.isMuted,
        );
      }

      state = state.copyWith(isConnectingAudio: false);
    } catch (e, stackTrace) {
      debugPrint("🚨 [Global Lounge Handshake Error]: $e");
      debugPrint("📜 Trace log details: $stackTrace");
      _handleConnectionFailure();
    }
  }

  void _handleConnectionFailure() {
    if (_isDisposed) return;
    final myId = ref.read(currentUserProvider).value?.id;
    if (myId != null && _activeRoundtableId != null) {
      _emitters.leaveSofa(roundtableId: _activeRoundtableId!, userId: myId);
    }
    _cleanupLiveKitHardware();
    state = state.copyWith(
      isConnectingAudio: false,
      myOccupiedSofaIndex: null,
      activeSpeakers: {},
    );
    _showToast("HANDSHAKE TIMEOUT // RETURNING TO LOUNGE", isError: true);
  }

  Future<void> toggleMute() async {
    if (_liveKitRoom == null || _isDisposed) return;
    try {
      final targetMute = !state.isMuted;
      await _liveKitRoom!.localParticipant?.setMicrophoneEnabled(!targetMute);
      state = state.copyWith(isMuted: targetMute);
    } catch (_) {}
  }

  Future<void> toggleSpeaker() async {
    if (_isDisposed) return;
    try {
      final targetSpeaker = !state.isSpeakerOn;
      if (_liveKitRoom != null) {
        await _liveKitRoom!.setSpeakerOn(targetSpeaker);
      }

      final session = await AudioSession.instance;
      if (targetSpeaker) {
        await session.configure(
          const AudioSessionConfiguration(
            avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
            avAudioSessionCategoryOptions:
                AVAudioSessionCategoryOptions.defaultToSpeaker,
            avAudioSessionMode: AVAudioSessionMode.voiceChat,
          ),
        );
      } else {
        await session.configure(
          const AudioSessionConfiguration(
            avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
            avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
            avAudioSessionMode: AVAudioSessionMode.voiceChat,
          ),
        );
      }

      state = state.copyWith(isSpeakerOn: targetSpeaker);
    } catch (_) {}
  }

  /// Tear down transmission channel gracefully (Hangup)
  Future<void> triggerHangup() async {
    final myId = ref.read(currentUserProvider).value?.id;
    final targetRoom = _activeRoundtableId;

    _showToast("TEARING DOWN MEDIA TUNNEL...");
    _cleanupLiveKitHardware();

    if (myId != null && targetRoom != null) {
      _emitters.leaveSofa(roundtableId: targetRoom, userId: myId);
    }

    // 🎯 FIX: Explicitly enforce empty UI models to clear the global overlay panel instantly
    state = LoungeSessionState(
      matrix: state.matrix, // Keep historical list cache intact
      myOccupiedSofaIndex: null, // Clear seat index out completely
      isConnectingAudio: false,
      isMuted: false,
      isSpeakerOn: true,
      activeSpeakers: const {},
    );
  }

  void _cleanupLiveKitHardware() {
    try {
      _liveKitListener?.dispose();
      _liveKitListener = null;

      if (_liveKitRoom != null) {
        // 🎯 FIX: In parent layouts, avoid invoking the blocking asynchronous disconnect() loop.
        // Directly disposing the instance frees the WebRTC stack, unlinks the local mic tracks,
        // and instantly stops the internal `EventsListenable.waitFor` timeout handler.
        _liveKitRoom!.dispose();
        _liveKitRoom = null;
      }
    } catch (e) {
      debugPrint("⚠️ LiveKit native structural cleanup error: $e");
    }
  }

  void closeEntireLoungeSession() {
    triggerHangup();
  }

  Function(String text, bool isError)? _uiToastCallback;
  void registerUiToastHook(Function(String text, bool isError) callback) {
    _uiToastCallback = callback;
  }

  void _showToast(String msg, {bool isError = false}) {
    if (_isDisposed) return;
    if (_uiToastCallback != null) {
      _uiToastCallback!(msg, isError);
    }
  }
}
