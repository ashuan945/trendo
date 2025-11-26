// lib/utils/ui_utils.dart
import 'package:flutter/material.dart';
import 'app_constants.dart';

class UIUtils {
  /// Calculate responsive font size based on screen width
  static double getResponsiveFontSize(
    BuildContext context,
    double baseFontSize, {
    double? minSize,
    double? maxSize,
  }) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / AppConstants.referenceScreenWidth;
    double scaledSize = baseFontSize * scaleFactor;
    
    double finalMinSize = minSize ?? AppConstants.minFontSize;
    double finalMaxSize = maxSize ?? AppConstants.maxFontSize;
    
    return scaledSize.clamp(finalMinSize, finalMaxSize);
  }

  /// Get screen width for responsive calculations
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Check if screen is small (mobile)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if screen is medium (tablet)
  static bool isMediumScreen(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  /// Check if screen is large (desktop)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isSmallScreen(context)) {
      return const EdgeInsets.all(12.0);
    } else if (isMediumScreen(context)) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  /// Get responsive margin based on screen size
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    if (isSmallScreen(context)) {
      return const EdgeInsets.all(8.0);
    } else if (isMediumScreen(context)) {
      return const EdgeInsets.all(12.0);
    } else {
      return const EdgeInsets.all(16.0);
    }
  }

  /// Create consistent box shadow
  static List<BoxShadow> getCardShadow({double opacity = 0.05}) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(opacity),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Create consistent border radius
  static BorderRadius getCardBorderRadius() {
    return BorderRadius.circular(AppConstants.defaultBorderRadius);
  }

  /// Create consistent input decoration
  static InputDecoration getInputDecoration({
    required String labelText,
    IconData? prefixIcon,
    String? prefixText,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.blue[600]) : null,
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: getCardBorderRadius(),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: getCardBorderRadius(),
        borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: getCardBorderRadius(),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: getCardBorderRadius(),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: getCardBorderRadius(),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.defaultPadding,
      ),
    );
  }

  /// Create consistent button style
  static ButtonStyle getPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      elevation: AppConstants.defaultElevation,
      shape: RoundedRectangleBorder(
        borderRadius: getCardBorderRadius(),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 12,
      ),
    );
  }

  /// Show consistent snack bar
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: getCardBorderRadius(),
        ),
      ),
    );
  }

  /// Show loading indicator
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: getCardBorderRadius(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: getResponsiveFontSize(context, 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}