import 'package:conextar/components/custom_button.dart';
import 'package:conextar/providers/roundtable/roundtable_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateBottomSheet extends ConsumerStatefulWidget {
  const CreateBottomSheet({super.key});

  @override
  ConsumerState<CreateBottomSheet> createState() => _CreateBottomSheetState();
}

class _CreateBottomSheetState extends ConsumerState<CreateBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitCreation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final response = await ref
        .read(roundtableProvider.notifier)
        .createRoundtable(_nameController.text.trim());

    setState(() => _isLoading = false);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: response.status
              ? Colors.teal
              : Theme.of(context).colorScheme.error,
        ),
      );
      if (response.status) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "INITIALIZE NEW TERMINAL",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Establish a new roundtable workspace cluster channel under your control.",
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.4),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: "Enter workspace name...",
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Workspace naming is required.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: "GENERATE WORKSPACE",
                      onPressed: _submitCreation,
                    ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
