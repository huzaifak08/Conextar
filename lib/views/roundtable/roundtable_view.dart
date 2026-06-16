import 'package:conextar/components/custom_button.dart';
import 'package:conextar/components/global_media_overlay.dart';
import 'package:conextar/providers/lounge_session/lounge_session_provider.dart';
import 'package:conextar/providers/roundtable/roundtable_provider.dart';
import 'package:conextar/views/profile/profile_view.dart';
import 'package:conextar/views/roundtable/widgets/create_bottom_sheet.dart';
import 'package:conextar/views/roundtable/widgets/join_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/roundtable_card.dart';

class RoundtableView extends ConsumerWidget {
  const RoundtableView({super.key});

  void _showJoinBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const JoinBottomSheet(),
    );
  }

  void _showCreateBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roundtablesAsync = ref.watch(roundtableProvider);
    final loungeSession = ref.watch(loungeSessionProvider);
    final theme = Theme.of(context);

    // 🎯 DOCK DETECTION: Adjust padding if the global media bar is active
    final bool isDockActive = loungeSession.myOccupiedSofaIndex != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("MY ROUNDTABLES"),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 26),
            tooltip: "Profile",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileView()),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      // 🧩 WRAPPED IN A STACK: Places the persistent voice controls on top of the list
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () =>
                ref.read(roundtableProvider.notifier).refreshRoundtables(),
            color: theme.colorScheme.primary,
            backgroundColor: theme.cardColor,
            child: roundtablesAsync.when(
              data: (roundtables) {
                if (roundtables.isEmpty) {
                  return _buildEmptyState(context);
                }
                return ListView.separated(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: isDockActive
                        ? 120
                        : 16, // 🎯 Pushes cards up so the overlay dock doesn't block them
                  ),
                  itemCount: roundtables.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return RoundtableCard(roundtable: roundtables[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    "Error loading terminals: $err",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ),
          ),

          // 🎙️ THE HUD OVERLAY: Anchored safely at the bottom of the stack
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: 130,
              ), // Positioned cleanly above FAB alignment rows
              child: GlobalMediaOverlay(),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: isDockActive ? 30 : 0,
        ), // 🎯 Shifts FAB up slightly if dock is active
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: "joinBtn",
              onPressed: () => _showJoinBottomSheet(context),
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
              ),
              child: const Icon(Icons.vpn_key_outlined),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.extended(
              heroTag: "createBtn",
              onPressed: () => _showCreateBottomSheet(context),
              icon: Icon(
                Icons.add,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              label: Text(
                "NEW TABLE",
                style: TextStyle(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        children: [
          Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 72,
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
                const SizedBox(height: 24),
                const Text(
                  "NO TERMINALS INITIALIZED",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "No historical or active roundtable data streams mapped to this profile identifier.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: "INITIALIZE CONNECTION",
                  onPressed: () => _showJoinBottomSheet(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
