import 'package:flutter/material.dart';
import 'redesigned_screens.dart';

class LegacyTrendingPage extends StatelessWidget {
  const LegacyTrendingPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      Text(
        'Em alta',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 8),
      Text(
        'Veja o que está fazendo sucesso agora.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 28),
      _ComingSoon(
        icon: Icons.local_fire_department_outlined,
        title: 'Conteúdo em alta',
        message: 'Os títulos mais populares aparecerão aqui.',
      ),
    ],
  );
}

class TrendingPage extends TrendingScreen {
  const TrendingPage({super.key});
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );
}
