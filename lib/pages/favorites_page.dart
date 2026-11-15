import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../core/app_haptics.dart';
import '../services/api_services.dart';
import '../widgets/content_card.dart';
import '../widgets/poster_hero_tag.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/tv_score_snackbar.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key, this.onExplore});

  final VoidCallback? onExplore;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with AutomaticKeepAliveClientMixin {
  final _api = ApiService();
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

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
      if (!mounted) return;
      AppHaptics.confirmation();
      setState(() {});
      TvScoreSnackbar.info(context, 'Removido dos favoritos.');
    } catch (_) {
      if (!mounted) return;
      AppHaptics.error();
      TvScoreSnackbar.error(context, 'Não foi possível remover o título.');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
            if (_loading && contents.isEmpty)
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 14.0;
                  final available = constraints.crossAxisExtent - 40;
                  final columns = ((available + spacing) / (130 + spacing))
                      .floor()
                      .clamp(1, 6);
                  final width = (available - spacing * (columns - 1)) / columns;
                  return SliverToBoxAdapter(
                    child: SkeletonGrid(
                      columns: columns,
                      mainAxisExtent: width * 1.5 + 65,
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    ),
                  );
                },
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
                        mainAxisExtent: width * 1.5 + 7 + 40 + 18,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: 20,
                      ),
                      itemBuilder: (context, index) {
                        final content = contents[index];
                        return Stack(
                          children: [
                            ContentCard(
                              content: content,
                              heroTag: posterHeroTag('favorites', content),
                              onFavoriteChanged: () => setState(() {}),
                              onChanged: () => setState(() {}),
                            ),
                            Positioned(
                              top: width * 1.5 - 56,
                              left: 8,
                              width: 48,
                              height: 48,
                              child: IconButton.filled(
                                tooltip: 'Remover dos favoritos',
                                onPressed: () => _removeContent(content),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black.withValues(
                                    alpha: .65,
                                  ),
                                  foregroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.all(12),
                                  shape: const CircleBorder(),
                                ),
                                icon: const Icon(
                                  HugeIconsSolid.heartRemove,
                                  size: 22,
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
