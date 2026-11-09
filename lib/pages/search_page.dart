import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tv_score_front_flutter/core/app_theme.dart';

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

  Timer? _debounce;
  int _searchVersion = 0;
  bool _loading = false;
  String? _error;
  List<Map<String, String>> _results = [];

  @override
  bool get wantKeepAlive => true;

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final version = ++_searchVersion;
    final term = value.trim();

    setState(() {
      _results = [];
      _error = null;
      _loading = term.isNotEmpty;
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

  @override
  void dispose() {
    _debounce?.cancel();
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
