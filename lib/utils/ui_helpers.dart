import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Navigasi dengan fade ringan - cepat dan tidak lag
Route<T> smoothRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, animation, __) => page,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

// Snackbar floating dengan icon
void showSnack(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isWarning = false,
  IconData? icon,
}) {
  if (!context.mounted) return;
  final Color bg = isError
      ? const Color(0xffef4444)
      : isWarning
          ? const Color(0xfff59e0b)
          : const Color(0xff22c55e);
  final IconData ic = icon ??
      (isError
          ? Icons.error_outline_rounded
          : isWarning
              ? Icons.warning_amber_rounded
              : Icons.check_circle_outline_rounded);
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(ic, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: bg,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}

void hapticLight() => HapticFeedback.lightImpact();
void hapticMedium() => HapticFeedback.mediumImpact();
void hapticSelect() => HapticFeedback.selectionClick();
