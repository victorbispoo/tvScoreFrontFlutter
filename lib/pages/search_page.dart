import 'package:flutter/material.dart';

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
  late Future<List<Map<String, String>>> _catalog;

  @override
  void initState() {
    super.initState();
    _catalog = ApiService().getHighlights();
  }

  @override
  bool get wantKeepAlive => true;
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  String _normalize(String value) {
    var result = value.toLowerCase().trim();
    const groups = {
      'a': 'áàâãä',
      'e': 'éèêë',
      'i': 'íìîï',
      'o': 'óòôõö',
      'u': 'úùûü',
      'c': 'ç',
    };
    groups.forEach((letter, accents) {
      for (final accent in accents.split('')) {
        result = result.replaceAll(accent, letter);
      }
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pesquisar',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Encontre filmes e séries do catálogo.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Busque por título ou gênero...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: () => setState(_query.clear),
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<Map<String, String>>>(
                  future: _catalog,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: FilledButton(
                          onPressed: () => setState(
                            () => _catalog = ApiService().getHighlights(),
                          ),
                          child: const Text('Tentar novamente'),
                        ),
                      );
                    }
                    final query = _normalize(_query.text);
                    final results = (snapshot.data ?? [])
                        .where(
                          (content) => _normalize(
                            '${content['title']} ${content['genre']}',
                          ).contains(query),
                        )
                        .toList();
                    if (results.isEmpty) {
                      return const Center(
                        child: Text(
                          'Nenhum título encontrado. Tente outro nome ou gênero.',
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
