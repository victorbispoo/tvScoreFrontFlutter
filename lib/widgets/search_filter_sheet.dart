import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../core/app_breakpoints.dart';
import '../models/search_filters.dart';

Future<SearchFilters?> showSearchFilters(
  BuildContext context, {
  required SearchFilters current,
  required Future<List<Map<String, dynamic>>> genres,
  required Future<List<Map<String, dynamic>>> Function() onRetryGenres,
}) => showModalBottomSheet<SearchFilters>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints:
      AppBreakpoints.supportsWidePages &&
          AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width)
      ? const BoxConstraints(maxWidth: 560, maxHeight: 760)
      : null,
  backgroundColor: Colors.transparent,
  builder: (context) => LayoutBuilder(
    builder: (context, constraints) {
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: SizedBox(
          height:
              (constraints.maxHeight - keyboard).clamp(
                0,
                constraints.maxHeight,
              ) *
              .86,
          child: SearchFilterSheet(
            current: current,
            genres: genres,
            onRetryGenres: onRetryGenres,
          ),
        ),
      );
    },
  ),
);

class SearchFilterSheet extends StatefulWidget {
  const SearchFilterSheet({
    super.key,
    required this.current,
    required this.genres,
    required this.onRetryGenres,
  });

  final SearchFilters current;
  final Future<List<Map<String, dynamic>>> genres;
  final Future<List<Map<String, dynamic>>> Function() onRetryGenres;

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late String? _type = widget.current.type;
  late final Set<String> _genres = {...widget.current.genres};
  late int? _minimumRating = widget.current.minimumRating;
  late final _year = TextEditingController(
    text: widget.current.year?.toString(),
  );
  late Future<List<Map<String, dynamic>>> _availableGenres = widget.genres;
  bool _invalidYear = false;

  @override
  void dispose() {
    _year.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _type = null;
      _genres.clear();
      _minimumRating = null;
      _year.clear();
      _invalidYear = false;
    });
  }

  void _apply() {
    final input = _year.text.trim();
    final year = int.tryParse(input);
    if (input.isNotEmpty &&
        (input.length != 4 || year == null || year < 1000)) {
      setState(() => _invalidYear = true);
      return;
    }
    Navigator.pop(
      context,
      SearchFilters(
        type: _type,
        genres: {..._genres},
        year: input.isEmpty ? null : year,
        minimumRating: _minimumRating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .14),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(onPressed: _clear, child: const Text('Limpar')),
                  IconButton(
                    tooltip: 'Fechar filtros',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(HugeIconsStroke.cancel01),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FilterTitle('Tipo'),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final (label, type) in [
                          ('Todos', null),
                          ('Filmes', 'MOVIE'),
                          ('Séries', 'TV'),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: _type == type,
                            onSelected: (_) => setState(() => _type = type),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _FilterTitle('Gêneros'),
                    Text(
                      'Mostra títulos com qualquer gênero selecionado.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _availableGenres,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData && !snapshot.hasError) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return TextButton(
                            onPressed: () => setState(() {
                              _availableGenres = widget.onRetryGenres();
                            }),
                            child: const Text(
                              'Não foi possível carregar gêneros. Tentar novamente',
                            ),
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          children: [
                            for (final genre in snapshot.data!)
                              FilterChip(
                                label: Text(genre['nome'] as String),
                                selected: _genres.contains(genre['nome']),
                                onSelected: (selected) => setState(() {
                                  final name = genre['nome'] as String;
                                  selected
                                      ? _genres.add(name)
                                      : _genres.remove(name);
                                }),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const _FilterTitle('Ano de lançamento'),
                    SizedBox(
                      width: 170,
                      child: TextField(
                        controller: _year,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 4,
                        onChanged: (_) {
                          if (_invalidYear) {
                            setState(() => _invalidYear = false);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Ex.: 2024',
                          counterText: '',
                          errorText: _invalidYear ? 'Informe 4 dígitos.' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _FilterTitle('Nota mínima TMDB'),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final rating in [null, 5, 6, 7, 8, 9])
                          ChoiceChip(
                            label: Text(
                              rating == null ? 'Qualquer' : '$rating+',
                            ),
                            selected: _minimumRating == rating,
                            onSelected: (_) =>
                                setState(() => _minimumRating = rating),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text('Aplicar filtros'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FilterTitle extends StatelessWidget {
  const _FilterTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );
}
