import 'package:conextar/components/custom_button.dart';
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
    final theme = Theme.of(context);

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
      body: RefreshIndicator(
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: roundtables.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
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
      floatingActionButton: Row(
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
