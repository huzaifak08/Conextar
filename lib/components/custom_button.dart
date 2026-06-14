import 'package:conextar/constants/theme.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = onPressed != null && !isLoading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // FIX: Swapped Border.solid out for standard Border.all
        border: Border.all(
          color: isActive
              ? ContextarTheme.neonCyan
              : ContextarTheme.darkSlateGreen,
          width: 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: ContextarTheme.neonCyan.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isActive ? onPressed : null,
        style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.all(
            isActive
                ? ContextarTheme.neonCyan
                : ContextarTheme.darkSlateGreen.withOpacity(0.3),
          ),
          foregroundColor: WidgetStateProperty.all(
            isActive
                ? ContextarTheme.backgroundBlack
                : ContextarTheme.mutedTextCyan.withOpacity(0.5),
          ),
          elevation: WidgetStateProperty.all(0),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ContextarTheme.backgroundBlack,
                  ),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}
