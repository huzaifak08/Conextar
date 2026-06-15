import 'dart:math' as math;
import 'package:conextar/models/lounge_state_model.dart';
import 'package:conextar/models/roundtable_model.dart';
import 'package:conextar/models/user_model.dart';
import 'package:conextar/providers/current_user/current_user_provider.dart';
import 'package:conextar/sockets/emitters/roundtable_emitters.dart';
import 'package:conextar/sockets/handlers/roundtable_handlers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';

class RoundtableExplore extends ConsumerStatefulWidget {
  final RoundtableModel roundtable;
  const RoundtableExplore({super.key, required this.roundtable});

  @override
  ConsumerState<RoundtableExplore> createState() => _RoundtableExploreState();
}

class _RoundtableExploreState extends ConsumerState<RoundtableExplore> {
  final _emitters = RoundtableEmitters();
  final _handlers = RoundtableHandlers();

  LoungeStateModel? _loungeState;
  int? _myOccupiedSofaIndex;

  // Real Hardware Media Engines
  Room? _liveKitRoom;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isConnectingAudio = false;

  // Dynamic Speaker Tracker
  Map<String, bool> _activeSpeakerMap = {};
  EventsListener<RoomEvent>? _liveKitRoomListener;

  @override
  void initState() {
    super.initState();

    // 1. Synchronize visual seating arrays
    _handlers.listenToLoungeState((updatedState) {
      if (mounted) {
        setState(() {
          _loungeState = updatedState;
          final myId = ref.read(currentUserProvider).value?.id;
          final seat = updatedState.sofas.indexWhere((s) => s.user?.id == myId);
          _myOccupiedSofaIndex = (seat != -1)
              ? updatedState.sofas[seat].sofaIndex
              : null;
        });
      }
    });

    // 2. Catch successful sofa claim event and instantly establish the WebRTC channel
    _handlers.listenToClaimSuccess((sofaIndex, token) async {
      if (!mounted) return;

      if (_isConnectingAudio || _liveKitRoom != null) {
        debugPrint(
          "⚠️ Connection routine already active. Dropping duplicate event loop.",
        );
        return;
      }

      setState(() {
        _myOccupiedSofaIndex = sofaIndex;
        _isConnectingAudio = true;
      });

      await _connectToLiveKitVoiceChannel(token);
    });

    _handlers.listenToClaimRejected(
      (reason) => _showStatusToast(reason, isError: true),
    );
    _handlers.listenToSystemErrors(
      (err) => _showStatusToast(err, isError: true),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        _emitters.enterRoundtable(
          roundtableId: widget.roundtable.id,
          userId: user.id,
        );
      }
    });
  }

  // LiveKit Core Connection Routine
  Future<void> _connectToLiveKitVoiceChannel(String token) async {
    try {
      debugPrint("📡 [LiveKit] Initializing fresh room session container...");
      _liveKitRoom = Room();

      // Configure Audio Session profile properties first
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

      if (_isSpeakerOn) {
        await session.setActive(true);
      }

      final roomOptions = RoomOptions(
        defaultAudioPublishOptions: const AudioPublishOptions(dtx: true),
      );

      const liveKitServerUrl = "ws://192.168.1.15:7880";

      debugPrint(
        "🎯 [LiveKit] Attempting signaling handshake connection to: $liveKitServerUrl",
      );

      await _liveKitRoom!
          .connect(liveKitServerUrl, token, roomOptions: roomOptions)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              throw Exception("Internal signaling tunnel timeout reached.");
            },
          );

      // Apply initial hardware routing toggle state
      await _liveKitRoom!.setSpeakerOn(_isSpeakerOn);

      // Link hardware speaker tracking listeners for glow effects
      _liveKitRoomListener = _liveKitRoom!.createListener();
      _liveKitRoomListener!.on<ActiveSpeakersChangedEvent>((event) {
        if (!mounted) return;

        final Map<String, bool> newSpeakerMap = {};
        for (var participant in event.speakers) {
          newSpeakerMap[participant.identity] = true;
        }

        setState(() {
          _activeSpeakerMap = newSpeakerMap;
        });
      });

      if (_liveKitRoom?.localParticipant != null) {
        await _liveKitRoom!.localParticipant!.setMicrophoneEnabled(!_isMuted);
      }

      if (mounted) {
        setState(() {
          _isConnectingAudio = false;
          _isMuted = false;
        });
        _showStatusToast("VOICE NODE ACTIVE // TRANSMITTING LINK");
      }
    } catch (e, stackTrace) {
      debugPrint("🚨 [LiveKit Handshake Error]: $e");
      debugPrint("📜 Trace log details: $stackTrace");

      _cleanupLiveKitHardware();

      // 🎯 SAFETY FALLBACK: Reset server seat status if WebRTC fails to establish
      final myId = ref.read(currentUserProvider).value?.id;
      if (myId != null) {
        _emitters.leaveSofa(roundtableId: widget.roundtable.id, userId: myId);
      }

      if (mounted) {
        setState(() {
          _isConnectingAudio = false;
          _myOccupiedSofaIndex = null;
          _activeSpeakerMap.clear();
        });
        _showStatusToast(
          "HANDSHAKE TIMEOUT // RETURNING TO LOUNGE",
          isError: true,
        );
      }
    }
  }

  void _cleanupLiveKitHardware() {
    try {
      _liveKitRoomListener?.dispose();
      _liveKitRoomListener = null;
      if (_liveKitRoom != null) {
        _liveKitRoom!.disconnect();
        _liveKitRoom!.dispose();
        _liveKitRoom = null;
      }
    } catch (e) {
      debugPrint("LiveKit memory cleanup failure: $e");
    }
  }

  Future<void> _toggleMute() async {
    if (_liveKitRoom == null) return;
    try {
      final newMuteState = !_isMuted;
      await _liveKitRoom!.localParticipant?.setMicrophoneEnabled(!newMuteState);
      setState(() => _isMuted = newMuteState);
      _showStatusToast(_isMuted ? "MIC FEED MUTED" : "MIC FEED UNMUTED");
    } catch (e) {
      _showStatusToast("TRACK CONTROL COMPROMISED", isError: true);
    }
  }

  // Switches between structural output routes (Loud Speaker phone vs. Device Earpiece receiver)
  Future<void> _toggleSpeaker() async {
    try {
      final newSpeakerState = !_isSpeakerOn;

      // 1. Core Hardware State Injection
      if (_liveKitRoom != null) {
        await _liveKitRoom!.setSpeakerOn(newSpeakerState);
      }

      // 2. Background session sync
      final session = await AudioSession.instance;
      if (newSpeakerState) {
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

      setState(() => _isSpeakerOn = newSpeakerState);
      _showStatusToast(
        _isSpeakerOn ? "SPEAKERPHONE ENGAGED" : "EARPIECE MODE ACTIVE",
      );
    } catch (e) {
      _showStatusToast("AUDIO ROUTING EXCEPTION", isError: true);
    }
  }

  Future<void> _triggerHangup(String userId) async {
    _showStatusToast("TEARING DOWN MEDIA TUNNEL...");
    _cleanupLiveKitHardware();

    _emitters.leaveSofa(roundtableId: widget.roundtable.id, userId: userId);

    setState(() {
      _myOccupiedSofaIndex = null;
      _isMuted = false;
      _isConnectingAudio = false;
      _activeSpeakerMap.clear();
    });
  }

  void _handleSofaTap(int index) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || _loungeState == null || _isConnectingAudio) return;

    final targetSofa = _loungeState!.sofas.firstWhere(
      (s) => s.sofaIndex == index,
    );

    if (targetSofa.user != null) {
      if (targetSofa.user!.id == user.id) {
        _triggerHangup(user.id);
      } else {
        _showStatusToast("CHANNEL SLOT OCCUPIED", isError: true);
      }
    } else {
      if (_myOccupiedSofaIndex != null) {
        _showStatusToast("VACATE CURRENT SOFA NODE FIRST", isError: true);
        return;
      }

      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }

      if (!status.isGranted) {
        _showStatusToast("MICROPHONE ACCESS DENIED BY SYSTEM", isError: true);
        return;
      }

      _emitters.claimSofa(
        roundtableId: widget.roundtable.id,
        userId: user.id,
        sofaIndex: index,
      );
    }
  }

  void _showStatusToast(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Colors.teal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _cleanupLiveKitHardware();
    _emitters.leaveRoundtableEngine();
    _handlers.clearAllRoomListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final waitingUsers = _loungeState?.waitingArea ?? [];
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roundtable.name.toUpperCase()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Text(
                  "PASSIVE SPECTATORS // ${waitingUsers.length} ONLINE",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              _buildWaitingArea(waitingUsers, theme),
              const Divider(height: 1, color: Colors.white10),
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size =
                          math.min(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ) *
                          0.78;
                      return SizedBox(
                        width: size,
                        height: size,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildCentralDisplay(size, theme),
                            ...List.generate(8, (index) {
                              final double radius = size * 0.38;
                              final double angle =
                                  (index * 2 * math.pi / 8) - (math.pi / 2);
                              final double x = radius * math.cos(angle);
                              final double y = radius * math.sin(angle);

                              final sofaSlot =
                                  _loungeState?.sofas.firstWhere(
                                    (s) => s.sofaIndex == index,
                                  ) ??
                                  SofaSlotModel(sofaIndex: index);

                              return Transform.translate(
                                offset: Offset(x, y),
                                child: Transform.rotate(
                                  // 🎯 SOFA ROTATION: Points the top surface of the asset directly inward
                                  angle: angle + math.pi,
                                  child: _buildInteractiveSofa(sofaSlot, theme),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
          if (_myOccupiedSofaIndex != null && currentUser != null)
            _buildMediaControlDock(theme, currentUser.id),
        ],
      ),
    );
  }

  Widget _buildWaitingArea(List<UserModel> waitingUsers, ThemeData theme) {
    return SizedBox(
      height: 80,
      child: waitingUsers.isEmpty
          ? Center(
              child: Text(
                "NO SPECTATORS IN WAITING STREAM",
                style: TextStyle(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: waitingUsers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, idx) {
                final u = waitingUsers[idx];
                return Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: u.profilePic != null
                          ? Image.network(u.profilePic!, fit: BoxFit.cover)
                          : const Icon(Icons.person),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 52,
                      child: Text(
                        u.name,
                        style: const TextStyle(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildCentralDisplay(double size, ThemeData theme) {
    final bool activeSession = _myOccupiedSofaIndex != null;
    return Container(
      width: size * 0.52,
      height: size * 0.52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(
            activeSession ? 0.25 : 0.08,
          ),
          width: 1.5,
        ),
        boxShadow: activeSession
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.03),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isConnectingAudio
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    activeSession
                        ? Icons.settings_voice_rounded
                        : Icons.radio_button_checked_outlined,
                    size: 20,
                    color: activeSession
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.primary.withOpacity(0.4),
                  ),
            const SizedBox(height: 8),
            Text(
              _isConnectingAudio
                  ? "AUTHENTICATING..."
                  : activeSession
                  ? "STREAM LIVE\nNODE NODE // 0$_myOccupiedSofaIndex"
                  : "SELECT SEAT\nTO TRANSMIT",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: activeSession
                    ? Colors.white
                    : theme.colorScheme.primary.withOpacity(0.4),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveSofa(SofaSlotModel slot, ThemeData theme) {
    final bool isOccupied = slot.user != null;
    final String initial = isOccupied
        ? slot.user!.name.trim().substring(0, 1).toUpperCase()
        : '';
    final bool isCurrentlySpeaking =
        isOccupied && (_activeSpeakerMap[slot.user!.id] ?? false);

    return GestureDetector(
      onTap: () => _handleSofaTap(slot.sofaIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: isCurrentlySpeaking
              ? [
                  BoxShadow(
                    color: theme.colorScheme.secondary.withOpacity(0.6),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              isOccupied
                  ? 'assets/images/activeSofa.png'
                  : 'assets/images/inActiveSofa.png',
              width: 68,
              height: 68,
              fit: BoxFit.contain,
            ),
            Positioned(
              top: 17,
              right: 9,
              child: AnimatedScale(
                scale: isOccupied ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: isCurrentlySpeaking
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isCurrentlySpeaking
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.primary)
                                .withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.scaffoldBackgroundColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaControlDock(ThemeData theme, String myUserId) {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isConnectingAudio
                        ? "NEURAL HANDSHAKE"
                        : "CONNECTED AUDIO SYSTEM",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _isConnectingAudio ? Colors.orange : Colors.teal,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isConnectingAudio
                        ? "CREATING MESH TUNNEL..."
                        : "TRANSMITTING ON SLOT 0$_myOccupiedSofaIndex",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDockButton(
                  icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  color: _isMuted
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  onPressed: _toggleMute,
                ),
                const SizedBox(width: 10),
                _buildDockButton(
                  icon: _isSpeakerOn
                      ? Icons.volume_up_rounded
                      : Icons.volume_mute_rounded,
                  color: _isSpeakerOn
                      ? theme.colorScheme.secondary
                      : Colors.grey,
                  onPressed: _toggleSpeaker,
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () => _triggerHangup(myUserId),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_end_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
