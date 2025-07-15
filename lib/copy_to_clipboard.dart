import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void copyToClipboardWithFeedback(
  BuildContext context,
  String icon,
  String label,
  String text,
) {
  if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) return;
  final trimmed = text.trim();
  if (trimmed.isEmpty) return;

  Clipboard.setData(ClipboardData(text: trimmed));
  HapticFeedback.selectionClick();

  final scaffold = ScaffoldMessenger.maybeOf(context);
  if (scaffold == null || !scaffold.mounted) return;

  scaffold
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Center(
          child: Text('$icon $label copied to clipboard'),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(
          horizontal: 40.0,
          vertical: 20.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
}
