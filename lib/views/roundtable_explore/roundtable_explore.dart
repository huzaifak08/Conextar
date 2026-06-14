import 'dart:math' as math;
import 'package:conextar/models/lounge_state_model.dart';
import 'package:conextar/models/roundtable_model.dart';
import 'package:conextar/models/user_model.dart';
import 'package:conextar/providers/current_user/current_user_provider.dart';
import 'package:conextar/sockets/emitters/roundtable_emitters.dart';
import 'package:conextar/sockets/handlers/roundtable_handlers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  String? _activeLiveKitToken;

  // Media state controls
  bool _isMuted = false;
  bool _isSpeakerOn = true;

  @override
  void initState() {
    super.initState();

    // 1. Hook up core state listening streams
    _handlers.listenToLoungeState((updatedState) {
      if (mounted) {
        setState(() {
          _loungeState = updatedState;
          final myId = ref.read(currentUserProvider).value?.id;

          final seat = updatedState.sofas.indexWhere((s) => s.user?.id == myId);
          _myOccupiedSofaIndex = (seat != -1)
              ? updatedState.sofas[seat].sofaIndex
              : null;

          // Clear active tokens locally if the backend drops the profile out of the sofa matrix
          if (_myOccupiedSofaIndex == null) {
            _activeLiveKitToken = null;
          }
        });
      }
    });

    // 2. Process real-time call engine authentication responses
    _handlers.listenToClaimSuccess((sofaIndex, token) {
      if (mounted) {
        setState(() {
          _myOccupiedSofaIndex = sofaIndex;
          _activeLiveKitToken = token;
        });
        _showStatusToast("VOICE NODE SECURED // CONNECTING STREAM");
        // TODO: Pass '_activeLiveKitToken' straight to your LiveKit Hardware Room Runner here
      }
    });

    _handlers.listenToClaimRejected(
      (reason) => _showStatusToast(reason, isError: true),
    );
    _handlers.listenToSystemErrors(
      (err) => _showStatusToast(err, isError: true),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).value;
      if (user != null)
        _emitters.enterRoundtable(
          roundtableId: widget.roundtable.id,
          userId: user.id,
        );
    });
  }

  void _handleSofaTap(int index) {
    final user = ref.read(currentUserProvider).value;
    if (user == null || _loungeState == null) return;

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
      _emitters.claimSofa(
        roundtableId: widget.roundtable.id,
        userId: user.id,
        sofaIndex: index,
      );
    }
  }

  void _triggerHangup(String userId) {
    _emitters.leaveSofa(roundtableId: widget.roundtable.id, userId: userId);
    _showStatusToast("DISCONNECTED FROM CALL STREAM");
    setState(() {
      _myOccupiedSofaIndex = null;
      _activeLiveKitToken = null;
    });
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
              // 1. Horizontal Waiting Strip
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

              // 2. Ring Arena Layout
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
                            ...List.generate(10, (index) {
                              final double radius = size * 0.38;
                              final double angle =
                                  (index * 2 * math.pi / 10) - (math.pi / 2);
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
                                  angle: angle + (math.pi / 2),
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

              // Pad space beneath the circular hub stack loop to accommodate the absolute HUD overlay frame panel
              const SizedBox(height: 100),
            ],
          ),

          // 3. Absolute HUD Overlay Panel Control Base Dock
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
    return Container(
      width: size * 0.52,
      height: size * 0.52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(
            _myOccupiedSofaIndex != null ? 0.25 : 0.08,
          ),
          width: 1.5,
        ),
        boxShadow: _myOccupiedSofaIndex != null
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
            Icon(
              _myOccupiedSofaIndex != null
                  ? Icons.settings_voice_rounded
                  : Icons.radio_button_checked_outlined,
              size: 20,
              color: _myOccupiedSofaIndex != null
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 8),
            Text(
              _myOccupiedSofaIndex != null
                  ? "STREAM LIVE\nNODE NODE // 0$_myOccupiedSofaIndex"
                  : "SELECT SEAT\nTO TRANSMIT",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _myOccupiedSofaIndex != null
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

    return GestureDetector(
      onTap: () => _handleSofaTap(slot.sofaIndex),
      child: SizedBox(
        width: 68,
        height: 68,
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
              top: 13,
              child: AnimatedScale(
                scale: isOccupied ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
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
                  const Text(
                    "CONNECTED AUDIO SYSTEM",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "TRANSMITTING ON CHANNEL NODE 0$_myOccupiedSofaIndex",
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
                // Mic Control Button
                _buildDockButton(
                  icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  color: _isMuted
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  onPressed: () => setState(() => _isMuted = !_isMuted),
                ),
                const SizedBox(width: 10),
                // Speaker Control Button
                _buildDockButton(
                  icon: _isSpeakerOn
                      ? Icons.volume_up_rounded
                      : Icons.volume_mute_rounded,
                  color: _isSpeakerOn
                      ? theme.colorScheme.secondary
                      : Colors.grey,
                  onPressed: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                ),
                const SizedBox(width: 14),
                // End Call Disconnect Button
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
