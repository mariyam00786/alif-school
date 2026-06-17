import 'package:flutter/material.dart';

import '../tokens/alif_colors.dart';
import '../tokens/alif_spacing.dart';

class AlifCard extends StatelessWidget {
  const AlifCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AlifSpacing.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AlifColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AlifColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
