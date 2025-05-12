import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Extension methods for String manipulation
extension StringExtension on String {
  String capitalize() => isEmpty ? this : "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
}

/// Extension methods for DateTime formatting and manipulation
extension DateTimeExtension on DateTime {
  String get formattedDate => DateFormat('MMM d, y').format(this);
  String get formattedDateTime => DateFormat('MMM d, y').add_jm().format(this);
  
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return isAfter(weekStart) && isBefore(weekEnd.add(const Duration(days: 1)));
  }
}

/// Helper methods for showing dialogs and snackbars
class UIHelpers {
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel ?? 'Cancel'),
          ),
          TextButton(
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error)
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel ?? 'Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// Animation helper methods
class AnimationHelpers {
  static Widget fadeTransition({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: child,
      ),
      child: child,
    );
  }

  static Widget slideTransition({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Offset begin = const Offset(0.0, 0.2),
    Offset end = Offset.zero,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      builder: (context, value, child) => Transform.translate(
        offset: value,
        child: child,
      ),
      child: child,
    );
  }
} 