import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../core/app_breakpoints.dart';
import '../core/app_haptics.dart';
import '../services/api_services.dart';
import '../widgets/content_card.dart';
import '../widgets/guest_account_prompt.dart';
import '../widgets/poster_hero_tag.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/tv_score_snackbar.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key, this.onExplore, this.bottomPadding = 20});

  final VoidCallback? onExplore;
  final double bottomPadding;

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
    ApiService.savedContentsRevision.addListener(_favoritesChanged);
    _loadFavorites();
  }

  void _favoritesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ApiService.savedContentsRevision.removeListener(_favoritesChanged);
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    if (!ApiService.hasSession) {
      _loading = false;
      return;
    }
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
      await _api.setSaved(content, false);
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
    final hasSession = ApiService.hasSession;
    final contents = hasSession
        ? ApiService.savedContents
        : const <Map<String, String>>[];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 14.0;
            final wide =
                AppBreakpoints.supportsWidePages &&
                constraints.maxWidth >= AppBreakpoints.tablet;
            final inset =
                20 +
                ((constraints.maxWidth - 1360) / 2).clamp(0.0, double.infinity);
            final available = (constraints.maxWidth - 2 * inset).clamp(
              1.0,
              double.infinity,
            );
            final columns = wide
                ? ((available + spacing) / 194).ceil()
                : ((available + spacing) / (130 + spacing)).floor().clamp(1, 6);
            final width = (available - spacing * (columns - 1)) / columns;
            final mainAxisExtent = width * 1.5 + 65;
            final gridPadding = EdgeInsets.fromLTRB(
              inset,
              0,
              inset,
              widget.bottomPadding,
            );
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(inset, 24, inset, 24),
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
                        if (hasSession) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${contents.length} ${contents.length == 1 ? 'título salvo' : 'títulos salvos'}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!hasSession)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        0,
                        24,
                        widget.bottomPadding,
                      ),
                      child: const GuestAccountPrompt(
                        icon: HugeIconsStroke.favourite,
                        title: 'Seus favoritos no TVScore',
                        message:
                            'Entre na sua conta para salvar filmes e séries favoritos.',
                      ),
                    ),
                  )
                else if (_loading && contents.isEmpty)
                  SliverToBoxAdapter(
                    child: SkeletonGrid(
                      columns: columns,
                      mainAxisExtent: mainAxisExtent,
                      shrinkWrap: true,
                      padding: gridPadding,
                    ),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: widget.bottomPadding),
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
                    ),
                  )
                else if (contents.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          0,
                          24,
                          widget.bottomPadding,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              HugeIconsStroke.favourite,
                              size: 40,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
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
                  SliverPadding(
                    padding: gridPadding,
                    sliver: SliverGrid.builder(
                      itemCount: contents.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: mainAxisExtent,
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
                                  backgroundColor:
                                      Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Theme.of(context).colorScheme.surface
                                      : Colors.black.withValues(alpha: .65),
                                  foregroundColor:
                                      Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Theme.of(context).colorScheme.error
                                      : Colors.redAccent,
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
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
