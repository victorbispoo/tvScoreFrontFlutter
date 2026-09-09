import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/tv_score_widgets.dart';

const _posterColors = [Color(0xFF9B2C2C), Color(0xFF315B89), Color(0xFF285943), Color(0xFF6C3F83)];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
    children: [
      Row(children: [Image.asset('lib/assets/logoTvScore.png', height: 34), const SizedBox(width: 8), const Text('TV Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
      const SizedBox(height: 8),
      const Text('Tenha acesso a avaliações dos melhores filmes e séries!', style: TextStyle(fontSize: 11, color: Colors.white60)),
      const SizedBox(height: 24),
      const PageHeading(title: 'Destaques', subtitle: 'Filmes e séries para você acompanhar'),
      const SizedBox(height: 12),
      SizedBox(height: 185, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: 4, separatorBuilder: (_, _) => const SizedBox(width: 10), itemBuilder: (_, index) => PosterTile(title: ['Oppenheimer', 'The Last of Us', 'Interestelar', 'Duna'][index], color: _posterColors[index]))),
      const SizedBox(height: 24),
      const PageHeading(title: 'Mais avaliados', subtitle: 'Descubra novos títulos para assistir'),
      const SizedBox(height: 12),
      const TvScorePanel(child: Row(children: [Icon(Icons.auto_awesome, color: Color(0xFFF7C948)), SizedBox(width: 10), Expanded(child: Text('Sua lista ainda está vazia. Comece a explorar!'))])),
    ],
  );
}

class TrendingScreen extends StatelessWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const PageHeading(title: 'Em Alta', subtitle: 'Descubra o que todo mundo está assistindo agora', icon: Icons.local_fire_department),
      const SizedBox(height: 18),
      Wrap(spacing: 8, runSpacing: 8, children: const [Chip(label: Text('Todos')), Chip(label: Text('Filmes')), Chip(label: Text('Séries')), Chip(label: Text('Animes'))]),
      const SizedBox(height: 22),
      const Text('POPULARES', style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: Colors.white54)),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 12, childAspectRatio: .54),
        itemCount: 4,
        itemBuilder: (_, index) => PosterTile(title: ['The Dark Knight', 'Inception', 'The Last of Us', 'Duna'][index], color: _posterColors[index]),
      ),
    ],
  );
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController();
  @override
  void dispose() { _queryController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    const PageHeading(title: 'Pesquisar', subtitle: 'Encontre filmes, séries e pessoas', icon: Icons.search),
    const SizedBox(height: 22),
    AppTextField(label: 'Busque por um título...', controller: _queryController, prefixIcon: const Icon(Icons.search), onChanged: (_) => setState(() {})),
    const SizedBox(height: 48),
    Icon(_queryController.text.isEmpty ? Icons.movie_outlined : Icons.search, size: 52, color: Colors.white38),
    const SizedBox(height: 14),
    Text(_queryController.text.isEmpty ? 'O que você quer assistir?' : 'Resultados em breve', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Text(_queryController.text.isEmpty ? 'Digite um título para começar a pesquisar.' : 'A busca será integrada à API nesta tela.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
  ]);
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    const PageHeading(title: 'Perfil', subtitle: 'Seu espaço no TV Score'),
    const SizedBox(height: 22),
    const Center(child: CircleAvatar(radius: 34, backgroundColor: Color(0xFF315B89), child: Text('JS'))),
    const SizedBox(height: 10),
    const Text('José Silva', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    const Text('Membro desde 2024', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.white54)),
    const SizedBox(height: 18),
    const Row(children: [ScoreMetric(icon: Icons.bookmark_outline, label: 'Filmes avaliados', value: '17'), SizedBox(width: 10), ScoreMetric(icon: Icons.star_outline, label: 'Séries avaliadas', value: '23')]),
    const SizedBox(height: 22),
    const PageHeading(title: 'Minha Lista', subtitle: 'Filmes e séries que você salvou', icon: Icons.bookmark_border),
    const SizedBox(height: 12),
    SizedBox(height: 165, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: 3, separatorBuilder: (_, _) => const SizedBox(width: 10), itemBuilder: (_, i) => PosterTile(title: ['Oppenheimer', 'The Last of Us', 'Duna'][i], color: _posterColors[i], compact: true))),
  ]);
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key, required this.isRegister, required this.onSubmit});
  final bool isRegister;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Image.asset('lib/assets/logoTvScore.png', height: 88),
    const SizedBox(height: 10),
    Text(isRegister ? 'Crie sua conta' : 'Bem-vindo de volta', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    const SizedBox(height: 28),
    if (isRegister) ...[const AppTextField(label: 'Nome'), const SizedBox(height: 12)],
    const AppTextField(label: 'E-mail', keyboardType: TextInputType.emailAddress),
    const SizedBox(height: 12),
    const AppTextField(label: 'Senha', obscureText: true),
    const SizedBox(height: 20),
    FilledButton(onPressed: onSubmit, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: AppTheme.primary), child: Text(isRegister ? 'Cadastrar' : 'Entrar')),
  ]))))));
}
