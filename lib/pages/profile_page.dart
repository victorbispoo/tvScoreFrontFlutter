import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../services/api_services.dart';
import 'favorites_page.dart';
import 'login_page.dart';
import 'my_reviews_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _api = ApiService();
  late Future<int> _reviewCount;

  Future<int> _fetchReviewCount() async {
    final reviews = await _api.getMyReviews();
    return reviews.length;
  }

  @override
  void initState() {
    super.initState();
    _reviewCount = _fetchReviewCount();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reviewCount = _fetchReviewCount();
  }

  Future<void> _logout() async {
    try {
      await _api.logout();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível sair. Tente novamente.'),
        ),
      );
      return;
    }
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _editProfile() async {
    var editedName = ApiService.userName;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar perfil'),
        content: TextFormField(
          initialValue: editedName,
          autofocus: true,
          maxLength: 60,
          onChanged: (value) => editedName = value,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, editedName.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (name == null || !mounted) return;
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe seu nome.')));
      return;
    }

    try {
      await _api.updateName(name);
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o perfil.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
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
            child: const Icon(Icons.person_outline, size: 42),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          ApiService.userName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          ApiService.userEmail,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: _editProfile,
              child: const Text('Editar perfil'),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _logout,
              child: const Text('Sair da conta'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Card(
          child: ListTile(
            leading: Icon(
              HugeIconsStroke.favourite,
              color: Colors.redAccent,
              size: 24,
            ),
            title: const Text('Favoritos'),
            subtitle: Text('${ApiService.savedContents.length} títulos salvos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesPage()),
              );
              if (mounted) setState(() {});
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(HugeIconsStroke.star, color: Colors.amber, size: 24),
            title: const Text('Minhas avaliações'),
            subtitle: FutureBuilder<int>(
              future: _reviewCount,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Text('Carregando contagem...');
                }
                if (snapshot.hasError) {
                  return TextButton(
                    onPressed: () {
                      setState(() {
                        _reviewCount = _fetchReviewCount();
                      });
                    },
                    child: const Text('Tentar carregar contagem novamente'),
                  );
                }
                final count = snapshot.data;
                return Text(
                  '$count ${count == 1 ? 'avaliação' : 'avaliações'}'
                  ' • Veja suas notas e comentários',
                );
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyReviewsPage()),
              );
              if (!mounted) return;
              setState(() {
                _reviewCount = _fetchReviewCount();
              });
            },
          ),
        ),
      ],
    );
  }
}
