import 'package:flutter/material.dart';

import '../tokens/alif_spacing.dart';

class AlifAppShell extends StatelessWidget {
  const AlifAppShell({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(
        child: Padding(padding: AlifSpacing.screen, child: body),
      ),
    );
  }
}
