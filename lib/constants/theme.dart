import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ContextarTheme {
  // Pure Sci-Fi Dark Palette extracted from assets
  static const Color backgroundBlack = Color(0xFF030708);
  static const Color darkSlateGreen = Color(0xFF162224);
  static const Color deepGreenCard = Color(0xFF0F181A);

  // Neon accents based on app_logo_neon.svg / app_icon.jpg
  static const Color neonCyan = Color(0xFF4DEEEA);
  static const Color electricAqua = Color(0xFF00E5FF);
  static const Color mutedTextCyan = Color(0xFF789D9C);

  static ThemeData buildThemeData(BuildContext ctx) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundBlack,
      cardColor: deepGreenCard,

      // Global Icon Styling (Optimized for SVGs and Neon Accents)
      iconTheme: const IconThemeData(color: neonCyan, size: 24),

      // Custom Floating/Elevated Component Colors
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: electricAqua,
        surface: deepGreenCard,
        error: Color(0xFFFF5252),
      ),

      // App Bar Configuration
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundBlack,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: neonCyan),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),

      // Cyber Glow Styled Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(
            Size(MediaQuery.sizeOf(ctx).width * 0.9, 52),
          ),
          padding: WidgetStateProperty.all<EdgeInsets>(
            const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
          shape: WidgetStateProperty.all<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: neonCyan, width: 1.5),
            ),
          ),
          foregroundColor: WidgetStateProperty.all<Color>(backgroundBlack),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return neonCyan.withOpacity(0.3);
            }
            return neonCyan; // Vibrant pop against deep backgrounds
          }),
          // Mimics the neon glow aura under buttons
          shadowColor: WidgetStateProperty.all<Color>(
            neonCyan.withOpacity(0.5),
          ),
          elevation: WidgetStateProperty.all<double>(8),
        ),
      ),

      // Custom Checkboxes and Modern Switches
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all(backgroundBlack),
        fillColor: WidgetStateProperty.all(neonCyan),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return electricAqua;
          return darkSlateGreen;
        }),
        thumbColor: WidgetStateProperty.all(Colors.white),
      ),

      // Deep Glow Dialog Styles
      dialogTheme: DialogThemeData(
        backgroundColor: deepGreenCard,
        elevation: 16,
        shadowColor: neonCyan.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkSlateGreen, width: 1),
        ),
      ),

      // Modern Inputs mimicking high-tech HUD fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSlateGreen.withOpacity(0.4),
        labelStyle: const TextStyle(color: mutedTextCyan),
        hintStyle: TextStyle(color: mutedTextCyan.withOpacity(0.5)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkSlateGreen, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonCyan, width: 1.5),
        ),
      ),

      // Typography Setup using Standard Platform System Fonts
      textTheme: Theme.of(ctx).textTheme.apply(
        fontFamily: 'DMSans', // Replace with your bundled font family if needed
        displayColor: Colors.white,
        bodyColor: Colors.white.withOpacity(0.7),
        decorationColor: neonCyan,
      ),
    );
  }

  /// Reusable background gradient builder mirroring the assets
  static BoxDecoration buildBackgroundGradient() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [backgroundBlack, darkSlateGreen, backgroundBlack],
        stops: [0.0, 0.5, 1.0],
      ),
    );
  }
}
