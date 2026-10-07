import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tv_score_front_flutter/core/app_theme.dart';
import 'package:tv_score_front_flutter/pages/my_list_page.dart';

class LegacyProfilePage extends StatelessWidget {
  const LegacyProfilePage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Perfil',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 28),
      Center(
        child: CircleAvatar(
          radius: 42,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedUser,
            size: 42,
            strokeWidth: 2,
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'José Silva',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      const Text(
        'Organize os filmes e séries que você acompanha.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      ),
      const SizedBox(height: 4),
      Center(
        child: SizedBox(
          width: 150,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF13243E),
            ),
            child: const Text('Editar perfil'),
          ),
        ),
      ),

      const SizedBox(height: 32),
      Card(
        child: ListTile(
          
          leading: HugeIcon(
            icon: HugeIcons.strokeRoundedBookmark01,
            size: 24,
            strokeWidth: 2,
          ),
          title: Text('Minha lista'),
          subtitle: Text('Veja seus filmes e séries salvos'),
          trailing: HugeIcon(
            icon: HugeIcons.strokeRoundedChevronRight,
            size: 24,
            strokeWidth: 2,
          ),
          onTap:(){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>  MyListPage()),
            );
          },
        ),
      ),
      Card(
        child: ListTile(
          leading: HugeIcon(
            icon: HugeIcons.strokeRoundedStar,
            size: 24,
            strokeWidth: 2,
          ),
          title: Text('Minhas avaliações'),
          subtitle: Text('Acesse suas avaliações de filmes e séries'),
          trailing: HugeIcon(
            icon: HugeIcons.strokeRoundedChevronRight,
            size: 24,
            strokeWidth: 2,
          ),
        ),
      ),
    ],
  );
}

class ProfilePage extends LegacyProfilePage {
  const ProfilePage({super.key});
}
