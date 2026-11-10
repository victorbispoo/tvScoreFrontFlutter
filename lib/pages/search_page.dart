import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tv_score_front_flutter/core/app_theme.dart';

import '../models/content_metadata.dart';
import '../services/api_services.dart';
import '../widgets/content_card.dart';

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

  Future<void> _search(String term, int version) async {
    try {
      final result = await _api.searchContents(term);

      if (!mounted || version != _searchVersion) return;

      setState(() {
        _results = result.contents;
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
          if (existing.add(content.contentKey)) {
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Não foi possível carregar mais resultados.'),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Tentar novamente',
            onPressed: _loadMore,
          ),
        ),
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
        title: const Text(
          'Pesquisar',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Encontre filmes e séries do catálogo.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _query,
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Busque por título...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: () {
                            _query.clear();
                            _onQueryChanged('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 20),
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
                    if (results.isEmpty) {
                      return const Center(
                        child: Text(
                          'Nenhum título encontrado. Tente outro nome.',
                          textAlign: TextAlign.center,
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

                        return GridView.builder(
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
