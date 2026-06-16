import 'dart:math' as math;
import 'package:conextar/components/global_media_overlay.dart';
import 'package:conextar/models/lounge_state_model.dart';
import 'package:conextar/models/roundtable_model.dart';
import 'package:conextar/models/user_model.dart';
import 'package:conextar/providers/current_user/current_user_provider.dart';
import 'package:conextar/providers/lounge_session/lounge_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoundtableExplore extends ConsumerStatefulWidget {
  final RoundtableModel roundtable;
  const RoundtableExplore({super.key, required this.roundtable});

  @override
  ConsumerState<RoundtableExplore> createState() => _RoundtableExploreState();
}

class _RoundtableExploreState extends ConsumerState<RoundtableExplore> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loungeSessionProvider.notifier).registerUiToastHook((
        text,
        isError,
      ) {
        if (mounted) _showStatusToast(text, isError: isError);
      });

      ref
          .read(loungeSessionProvider.notifier)
          .initLoungePipeline(widget.roundtable.id);
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
    // 🎯 FIX: Completely removed closeEntireLoungeSession() from here.
    // Riverpod's autoDispose handles the unmount sequence safely now,
    // avoiding asynchronous race conditions inside your framework tree.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(loungeSessionProvider);
    final waitingUsers = session.matrix?.waitingArea ?? [];
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
                            _buildCentralDisplay(size, theme, session),
                            ...List.generate(8, (index) {
                              final double radius = size * 0.38;
                              final double angle =
                                  (index * 2 * math.pi / 8) - (math.pi / 2);
                              final double x = radius * math.cos(angle);
                              final double y = radius * math.sin(angle);

                              final sofaSlot =
                                  session.matrix?.sofas.firstWhere(
                                    (s) => s.sofaIndex == index,
                                  ) ??
                                  SofaSlotModel(sofaIndex: index);

                              return Transform.translate(
                                offset: Offset(x, y),
                                child: Transform.rotate(
                                  angle: angle + math.pi,
                                  child: _buildInteractiveSofa(
                                    sofaSlot,
                                    theme,
                                    session,
                                  ),
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
          if (session.myOccupiedSofaIndex != null && currentUser != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: const GlobalMediaOverlay(),
            ),
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

  Widget _buildCentralDisplay(double size, ThemeData theme, var session) {
    final bool activeSession = session.myOccupiedSofaIndex != null;
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
            session.isConnectingAudio
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
              session.isConnectingAudio
                  ? "AUTHENTICATING..."
                  : activeSession
                  ? "STREAM LIVE\nNODE NODE // 0${session.myOccupiedSofaIndex}"
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

  Widget _buildInteractiveSofa(
    SofaSlotModel slot,
    ThemeData theme,
    var session,
  ) {
    final bool isOccupied = slot.user != null;
    final String initial = isOccupied
        ? slot.user!.name.trim().substring(0, 1).toUpperCase()
        : '';
    final bool isCurrentlySpeaking =
        isOccupied && (session.activeSpeakers[slot.user!.id] ?? false);

    return GestureDetector(
      onTap: () => ref
          .read(loungeSessionProvider.notifier)
          .handleSofaTap(slot.sofaIndex),
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
                      fontSize: 16,
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
}
