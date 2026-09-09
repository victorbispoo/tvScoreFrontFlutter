import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: AppTheme.pagePadding,
    children: [
      if (title.isNotEmpty)
        Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        Text(subtitle!, style: const TextStyle(color: Colors.white70)),
      ],
      ...children,
    ],
  );
}
