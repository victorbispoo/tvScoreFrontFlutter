import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../services/api_services.dart';
import '../widgets/content_card.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key, this.onExplore});

  final VoidCallback? onExplore;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.loadFavorites();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível carregar seus favoritos.');
    } finally {
      if (mounted) setState(() => _loading = false);
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
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Favoritos',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${contents.length} ${contents.length == 1 ? 'título salvo' : 'títulos salvos'}',
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadFavorites,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
            else if (contents.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          HugeIconsStroke.favourite,
                          size: 40,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sua lista está vazia',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Explore filmes e séries e salve os que você gosta.',
                          textAlign: TextAlign.center,
                        ),
                        if (widget.onExplore != null) ...[
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: widget.onExplore,
                            child: const Text('Explorar títulos'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  const horizontalPadding = 20.0;
                  const spacing = 14.0;
                  final available =
                      constraints.crossAxisExtent - horizontalPadding * 2;
                  final columns = ((available + spacing) / (130 + spacing))
                      .floor()
                      .clamp(1, 6);
                  final width = (available - spacing * (columns - 1)) / columns;
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    sliver: SliverGrid.builder(
                      itemCount: contents.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: width * 1.5 + 7 + 40 + 18 + 48,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: 20,
                      ),
                      itemBuilder: (context, index) {
                        final content = contents[index];
                        return Column(
                          children: [
                            ContentCard(
                              content: content,
                              onChanged: () => setState(() {}),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => _removeContent(content),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white60,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 48),
                                ),
                                icon: const Icon(
                                  HugeIconsStroke.favourite,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Remover favorito',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
