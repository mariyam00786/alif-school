import 'package:flutter/material.dart';

import '../tokens/alif_spacing.dart';

class AlifButton extends StatelessWidget {
  const AlifButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    return FilledButton(
      onPressed: effectiveOnPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size(expand ? double.infinity : 0, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: AlifSpacing.lg,
          vertical: AlifSpacing.md,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AlifSpacing.sm),
          ] else if (leading != null) ...[
            leading!,
            const SizedBox(width: AlifSpacing.sm),
          ],
          Text(label),
        ],
      ),
    );
  }
}
