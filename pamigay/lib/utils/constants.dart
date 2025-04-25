import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// API Constants
// Using dotenv for environment-specific configuration
String getBaseUrl() {
  return dotenv.get('API_BASE_URL');
}

// Dynamic baseUrl from environment variables
final String baseUrl = getBaseUrl();

// Color Constants
class PamigayColors {
  static const Color primary = Color(0xFF00C2DF); // Turquoise from the logo
  static const Color secondary = Colors.white;
  static const Color accent = Colors.black;
  static const Color background = Colors.white;
  static const Color error = Color(0xFFFF3B30);
  static const Color success = Color(0xFF4CD964);
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF6E6E6E);
}

// Text Styles
class PamigayTextStyles {
  static const TextStyle heading = TextStyle(
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.bold,
    fontSize: 24,
    color: PamigayColors.textPrimary,
  );

  static const TextStyle subheading = TextStyle(
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.bold,
    fontSize: 18,
    color: PamigayColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.normal,
    fontSize: 16,
    color: PamigayColors.textPrimary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: Colors.white,
  );

  static const TextStyle small = TextStyle(
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.normal,
    fontSize: 14,
    color: PamigayColors.textSecondary,
  );
}

// Button Styles
class PamigayButtonStyles {
  static ButtonStyle primaryButton = ButtonStyle(
    backgroundColor: MaterialStateProperty.all<Color>(PamigayColors.primary),
    foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
    padding: MaterialStateProperty.all<EdgeInsets>(
      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  static ButtonStyle secondaryButton = ButtonStyle(
    backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
    foregroundColor: MaterialStateProperty.all<Color>(PamigayColors.primary),
    padding: MaterialStateProperty.all<EdgeInsets>(
      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: PamigayColors.primary),
      ),
    ),
  );
}

// Input Decorations
class PamigayInputDecorations {
  static InputDecoration textFieldDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: PamigayTextStyles.small,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: PamigayColors.primary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
