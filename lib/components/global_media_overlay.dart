import 'package:conextar/providers/lounge_session/lounge_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalMediaOverlay extends ConsumerWidget {
  const GlobalMediaOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(loungeSessionProvider);
    final theme = Theme.of(context);

    // 🎯 HIDE IF USER IS NOT ACTIVE ON ANY SOFA CHANNEL STREAMS
    if (session.myOccupiedSofaIndex == null) {
      return const SizedBox.shrink();
    }

    return Container(
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
                  session.isConnectingAudio
                      ? "NEURAL HANDSHAKE"
                      : "BACKGROUND VOICE NODE UNLOCKED",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: session.isConnectingAudio
                        ? Colors.orange
                        : Colors.teal,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session.isConnectingAudio
                      ? "CREATING MESH TUNNEL..."
                      : "TRANSMITTING ON SLOT 0${session.myOccupiedSofaIndex}",
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
                icon: session.isMuted
                    ? Icons.mic_off_rounded
                    : Icons.mic_rounded,
                color: session.isMuted
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                onPressed: () =>
                    ref.read(loungeSessionProvider.notifier).toggleMute(),
              ),
              const SizedBox(width: 10),
              _buildDockButton(
                icon: session.isSpeakerOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_mute_rounded,
                color: session.isSpeakerOn
                    ? theme.colorScheme.secondary
                    : Colors.grey,
                onPressed: () =>
                    ref.read(loungeSessionProvider.notifier).toggleSpeaker(),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () =>
                    ref.read(loungeSessionProvider.notifier).triggerHangup(),
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
