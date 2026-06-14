import 'package:conextar/components/custom_button.dart';
import 'package:conextar/providers/roundtable/roundtable_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JoinBottomSheet extends ConsumerStatefulWidget {
  const JoinBottomSheet({super.key});

  @override
  ConsumerState<JoinBottomSheet> createState() => _JoinBottomSheetState();
}

class _JoinBottomSheetState extends ConsumerState<JoinBottomSheet> {
  final TextEditingController _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitJoinCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final response = await ref
        .read(roundtableProvider.notifier)
        .joinWithCode(_codeController.text.trim());

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
                "SECURE NODE ACCESS",
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
                "Input the 4-digit system authentication token to link stream logs.",
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.4),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _codeController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: theme.colorScheme.secondary,
                ),
                decoration: const InputDecoration(
                  counterText: "",
                  hintText: "••••",
                ),
                validator: (value) {
                  if (value == null || value.trim().length != 4) {
                    return "Sequence requires exactly 4 characters.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: "AUTHENTICATE LINK",
                      onPressed: _submitJoinCode,
                    ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
