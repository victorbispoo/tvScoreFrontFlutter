import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../widgets/app_page.dart';

class MyListPage extends StatelessWidget {
  const MyListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha lista')),
      body: const SafeArea(
        child: AppPage(
          title: '',
          subtitle: 'Seus filmes e séries salvos aparecem aqui.',
          children: [
            SizedBox(height: 32),
            // Substitua este estado vazio pela lista de filmes salvos.
            Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedBookmark01,
                      size: 48,
                      strokeWidth: 2,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Sua lista está vazia',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Salve filmes e séries para acompanhar depois.',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
