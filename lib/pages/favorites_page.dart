import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../services/api_services.dart';
import '../widgets/content_card.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _api = ApiService();

  bool _loading = true;
  String? _error;

  @override
  void initState(){
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async{
    setState(() {
      _loading= true;
      _error = null;
    });

    try {
      await _api.loadFavorites();
    } catch (_){
      if(!mounted) return;

      setState(() {
        _error = 'Não foi possível carregar seus favoritos.';
      });
    } finally {
      if(mounted){
        setState(() => _loading=false);
      }
    }
  }

  Future<void> _removeContent(Map<String, String> content) async {
    try {
      await _api.toggleSaved(content);
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível remover o título.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contents = ApiService.savedContents;
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: SafeArea(
        child: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error !=null
          ? Center(
            child: Column(
              mainAxisSize: .min,
              children: [
                Text(_error!),
                const SizedBox(height: 12),
                FilledButton(onPressed: _loadFavorites, child: const Text('Tentar Novamente'))
              ],
            ),
          )
        : contents.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        HugeIconsStroke.favourite,
                        size: 56,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Sua lista está vazia',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Abra um título na Home ou na busca e adicione à sua lista.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisExtent: 340,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 20,
                ),
                itemCount: contents.length,
                itemBuilder: (context, index) => Column(
                  children: [
                    Expanded(
                      child: ContentCard(
                        content: contents[index],
                        onChanged: () => setState(() {}),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _removeContent(contents[index]),
                      icon: const Icon(
                        Icons.bookmark_remove_outlined,
                        size: 18,
                      ),
                      label: const Text('Remover'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
