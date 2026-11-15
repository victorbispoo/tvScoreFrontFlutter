import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:tv_score_front_flutter/core/app_theme.dart';

import '../models/content_metadata.dart';
import '../models/search_filters.dart';
import '../services/api_services.dart';
import '../widgets/content_card.dart';
import '../widgets/search_filter_sheet.dart';
import '../widgets/tv_score_snackbar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with AutomaticKeepAliveClientMixin {
  final _query = TextEditingController();
  final _api = ApiService();
  final _scrollController = ScrollController();
  bool _loadMoreFailed = false;
  Timer? _debounce;
  int _searchVersion = 0;
  bool _loading = false;
  bool _loadingMore = false;
  int _currentPage = 0;
  int _totalPages = 0;
  SearchFilters _filters = const SearchFilters();
  Future<List<Map<String, dynamic>>>? _genresFuture;
  String? _error;
  List<Map<String, String>> _results = [];

  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadMoreFailed) return;

    if (_scrollController.position.extentAfter <= 300) {
      _loadMore();
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final version = ++_searchVersion;
    final term = value.trim();

    setState(() {
      _loadMoreFailed = false;
      _results = [];
      _error = null;
      _loading = term.isNotEmpty;
      _loadingMore = false;
      _currentPage = 0;
      _totalPages = 0;
    });

    if (term.isEmpty) return;

    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _search(term, version),
    );
  }

  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();
    final selected = await showSearchFilters(
      context,
      current: _filters,
      genres: _genresFuture ??= _api.getAvailableGenres(),
      onRetryGenres: () => _genresFuture = _api.getAvailableGenres(),
    );
    if (!mounted || selected == null) return;
    _filters = selected;
    _onQueryChanged(_query.text);
  }

  Future<void> _search(String term, int version) async {
    try {
      final result = await _api.searchContents(term);

      if (!mounted || version != _searchVersion) return;

      setState(() {
        _results = result.contents.where(_filters.matches).toList();
        _currentPage = result.page;
        _totalPages = result.totalPages;
      });
    } catch (error) {
      if (!mounted || version != _searchVersion) return;
      debugPrint('Falha na pesquisa: $error');

      setState(() {
        _error = 'Não foi possível pesquisar. Tente novamente.';
      });
    } finally {
      if (mounted && version == _searchVersion) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _currentPage == 0) return;
    if (_currentPage >= _totalPages ||
        _currentPage >= ApiService.maxSearchPage) {
      return;
    }

    final term = _query.text.trim();
    if (term.isEmpty) return;

    final version = _searchVersion;
    final nextPage = _currentPage + 1;

    setState(() {
      _loadingMore = true;
      _loadMoreFailed = false;
    });

    try {
      final result = await _api.searchContents(term, page: nextPage);

      if (!mounted || version != _searchVersion) return;

      setState(() {
        final existing = _results.map((content) => content.contentKey).toSet();

        for (final content in result.contents) {
          if (_filters.matches(content) && existing.add(content.contentKey)) {
            _results.add(content);
          }
        }

        _currentPage = result.page;
        _totalPages = result.totalPages;
      });
    } catch (error) {
      if (!mounted || version != _searchVersion) return;

      debugPrint('Falha ao carregar mais resultados: $error');

      setState(() {
        _loadMoreFailed = true;
      });

      TvScoreSnackbar.error(
        context,
        'Não foi possível carregar mais resultados.',
        actionLabel: 'Tentar novamente',
        onAction: _loadMore,
      );
    } finally {
      if (mounted && version == _searchVersion) {
        setState(() {
          _loadingMore = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(HugeIconsStroke.arrowLeft01),
        ),
        title: const Text(
          'Pesquisar',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: TextField(
                          controller: _query,
                          onChanged: _onQueryChanged,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Busque por título...',
                            prefixIcon: const Icon(
                              HugeIconsStroke.search01,
                              size: 20,
                            ),
                            suffixIcon: _query.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Limpar busca',
                                    onPressed: () {
                                      _query.clear();
                                      _onQueryChanged('');
                                    },
                                    icon: const Icon(
                                      HugeIconsStroke.cancel01,
                                      size: 18,
                                    ),
                                  ),
                            filled: true,
                            fillColor: const Color(0xEB14253D),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: AppTheme.primary.withValues(alpha: .16),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: AppTheme.primary.withValues(alpha: .16),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: AppTheme.primary,
                                width: 1.4,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Filtros',
                        onPressed: _openFilters,
                        icon: const Icon(
                          HugeIconsStroke.filterHorizontal,
                          size: 21,
                        ),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(52, 52),
                          backgroundColor: AppTheme.surface,
                          foregroundColor: _filters.isActive
                              ? AppTheme.primary
                              : Colors.white70,
                          side: BorderSide(
                            color: AppTheme.primary.withValues(
                              alpha: _filters.isActive ? .55 : .16,
                            ),
                          ),
                        ),
                      ),
                      if (_filters.isActive)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_query.text.trim().isEmpty)
                const Text(
                  'Encontre filmes e séries do catálogo.',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                )
              else
                Text(
                  'Resultados para “${_query.text.trim()}”',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (_query.text.trim().isEmpty) {
                      return const Center(
                        child: Text('Digite o nome de um filme ou série.'),
                      );
                    }
                    if (_loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (_error != null) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => _onQueryChanged(_query.text),
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      );
                    }
                    final results = _results;
                    final hasMore =
                        _currentPage > 0 &&
                        _currentPage < _totalPages &&
                        _currentPage < ApiService.maxSearchPage;
                    if (results.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hasMore
                                  ? 'Nenhum título corresponde aos filtros nesta página.'
                                  : _filters.isActive
                                  ? 'Nenhum título encontrado. Ajuste os filtros ou o nome.'
                                  : 'Nenhum título encontrado. Tente outro nome.',
                              textAlign: TextAlign.center,
                            ),
                            if (hasMore) ...[
                              const SizedBox(height: 12),
                              _loadingMore
                                  ? const CircularProgressIndicator()
                                  : TextButton(
                                      onPressed: _loadMore,
                                      child: const Text('Buscar mais páginas'),
                                    ),
                            ],
                          ],
                        ),
                      );
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 14.0;
                        final columns = (constraints.maxWidth / 174).ceil();
                        final cardWidth =
                            (constraints.maxWidth - spacing * (columns - 1)) /
                            columns;

                        return Column(
                          children: [
                            Expanded(
                              child: GridView.builder(
                                controller: _scrollController,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      mainAxisExtent: cardWidth * 1.5 + 64,
                                      crossAxisSpacing: spacing,
                                      mainAxisSpacing: 20,
                                    ),
                                itemCount: results.length,
                                itemBuilder: (_, index) =>
                                    ContentCard(content: results[index]),
                              ),
                            ),
                            if (hasMore)
                              _loadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(),
                                    )
                                  : TextButton(
                                      onPressed: _loadMore,
                                      child: Text(
                                        _loadMoreFailed
                                            ? 'Tentar novamente'
                                            : 'Carregar mais',
                                      ),
                                    ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
