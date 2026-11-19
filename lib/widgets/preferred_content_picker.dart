import 'dart:async';

import 'package:flutter/material.dart';

import '../models/content_metadata.dart';
import '../services/api_services.dart';
import 'content_card.dart';
import 'tv_score_segmented_control.dart';

class PreferredContentPicker extends StatefulWidget {
  const PreferredContentPicker({
    super.key,
    required this.header,
    required this.selected,
    required this.onChanged,
  });
  final Map<(String?, String?), Map<String, String>> selected;
  final Widget header;
  final VoidCallback onChanged;

  @override
  State<PreferredContentPicker> createState() => _PreferredContentPickerState();
}

class _PreferredContentPickerState extends State<PreferredContentPicker> {
  final _api = ApiService();
  final _query = TextEditingController();
  final _pages =
      <
        (String, int),
        Future<({List<Map<String, String>> contents, int page, int totalPages})>
      >{};
  List<Map<String, String>> _results = [];
  Timer? _debounce;
  int _version = 0;
  int _page = 0;
  int _totalPages = 1;
  bool _loading = false;
  String? _error;
  String _type = 'ALL';

  @override
  void initState() {
    super.initState();
    _load(1, _version);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    final version = ++_version;
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
      _page = 0;
    });
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _load(1, version),
    );
  }

  Future<void> _load(int page, int version) async {
    final term = _query.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });
    final key = (term, page);
    try {
      final result = await _pages.putIfAbsent(
        key,
        () => term.isEmpty
            ? _api.getPreferredContentOptions(page: page)
            : _api.searchContents(term, page: page),
      );
      if (!mounted || version != _version) return;
      setState(() {
        final combined = {
          for (final item in page == 1 ? <Map<String, String>>[] : _results)
            item.contentKey: item,
        };
        for (final item in result.contents) {
          combined[item.contentKey] = item;
        }
        _results = combined.values.toList();
        _page = result.page;
        _totalPages = result.totalPages;
      });
    } catch (_) {
      _pages.remove(key);
      if (mounted && version == _version) {
        setState(() => _error = 'Não foi possível carregar os conteúdos.');
      }
    } finally {
      if (mounted && version == _version) setState(() => _loading = false);
    }
  }

  void _toggle(Map<String, String> content) {
    final key = content.contentKey;
    if (widget.selected.containsKey(key)) {
      widget.selected.remove(key);
    } else if (widget.selected.length < 5) {
      widget.selected[key] = content;
    }
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results
        .where((item) => _type == 'ALL' || item['type'] == _type)
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.header,
          TextField(
            controller: _query,
            onChanged: _search,
            decoration: const InputDecoration(
              labelText: 'Pesquisar filmes e séries',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          TvScoreSegmentedControl<String>(
            options: const {'ALL': 'Todos', 'MOVIE': 'Filmes', 'TV': 'Séries'},
            selectedValue: _type,
            onChanged: (value) => setState(() => _type = value),
          ),
          if (widget.selected.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: [
                for (final content in widget.selected.values)
                  InputChip(
                    label: Text(
                      '${content['title']} (${content['type'] == 'TV' ? 'Série' : 'Filme'})',
                    ),
                    onDeleted: () => _toggle(content),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (_query.text.trim().isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Sugestões baseadas nas preferências já salvas. As novas escolhas serão aplicadas ao concluir.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          if (results.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 520
                    ? ((constraints.maxWidth + 12) / 162).floor().clamp(3, 6)
                    : 2;
                final width =
                    (constraints.maxWidth - 12 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  children: [
                    for (final content in results)
                      SizedBox(
                        key: ValueKey(content.contentKey),
                        width: width,
                        child: _card(content),
                      ),
                  ],
                );
              },
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(
              onPressed: () => _load(_page + 1, _version),
              child: const Text('Tentar novamente'),
            ),
          ] else if (!_loading && results.isEmpty)
            const Text('Nenhum título encontrado nesta categoria.'),
          if (!_loading &&
              _error == null &&
              _page < _totalPages &&
              _page < ApiService.maxSearchPage)
            TextButton(
              onPressed: () => _load(_page + 1, _version),
              child: const Text('Carregar mais'),
            ),
        ],
      ),
    );
  }

  Widget _card(Map<String, String> content) {
    final selected = widget.selected.containsKey(content.contentKey);
    final enabled = selected || widget.selected.length < 5;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      onTap: enabled ? () => _toggle(content) : null,
      label:
          '${content['title']}, ${content['type'] == 'TV' ? 'Série' : 'Filme'}',
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enabled ? 1 : .4,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? () => _toggle(content) : null,
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Theme.of(context).colorScheme.outlineVariant
                        : Colors.white.withValues(alpha: .08),
                    width: 1.5,
                  ),
                ),
                foregroundDecoration: BoxDecoration(
                  color: selected
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: .16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    ExcludeFocus(
                      child: IgnorePointer(
                        child: ContentCard(content: content),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: AnimatedOpacity(
                        opacity: selected ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
