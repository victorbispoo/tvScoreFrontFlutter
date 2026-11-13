import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/api_services.dart';

class GenrePreferencesDialog extends StatefulWidget {
  const GenrePreferencesDialog({super.key, this.isEditing = false});

  final bool isEditing;

  @override
  State<GenrePreferencesDialog> createState() => _GenrePreferencesDialogState();
}

class _GenrePreferencesDialogState extends State<GenrePreferencesDialog> {
  final _api = ApiService();
  final _selected = <String>{};
  late Future<List<Map<String, dynamic>>> _genres;
  bool _saving = false;
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _genres = _loadGenres();
  }

  Future<List<Map<String, dynamic>>> _loadGenres() async {
    _loaded = false;
    final (genres, preferred) = await (
      _api.getAvailableGenres(),
      widget.isEditing
          ? _api.getPreferredGenres()
          : Future.value(<Map<String, dynamic>>[]),
    ).wait;

    if (mounted) {
      final available = genres
          .map((genre) => genre['codigo'] as String)
          .toSet();
      setState(() {
        _selected
          ..clear()
          ..addAll(
            preferred
                .map((genre) => genre['codigo'] as String)
                .where(available.contains),
          );
        _loaded = true;
      });
    }
    return genres;
  }

  Future<void> _save() async {
    if (!_loaded || _saving || (!widget.isEditing && _selected.isEmpty)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.savePreferredGenres(_selected.toList());
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível salvar. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  IconData _genreIcon(String code) => switch (code) {
    'tmdb-10759' => Icons.explore_outlined,
    'tmdb-12' => Icons.hiking_outlined,
    'tmdb-28' => Icons.sports_martial_arts_outlined,
    'tmdb-10770' => Icons.live_tv_outlined,
    'animacao' => Icons.animation_outlined,
    'comedia' => Icons.theater_comedy_outlined,
    'crime' => Icons.local_police_outlined,
    'documentario' => Icons.public_outlined,
    'drama' => Icons.auto_stories_outlined,
    'familia' => Icons.family_restroom_outlined,
    'tmdb-14' => Icons.auto_awesome_outlined,
    'tmdb-878' => Icons.science_outlined,
    'tmdb-10752' => Icons.military_tech_outlined,
    'tmdb-36' => Icons.history_edu_outlined,
    'tmdb-10762' => Icons.child_care_outlined,
    'misterio' => Icons.travel_explore_outlined,
    'faroeste' => Icons.landscape_outlined,
    'tmdb-10402' => Icons.music_note_outlined,
    'tmdb-10763' => Icons.newspaper_outlined,
    'tmdb-10764' => Icons.visibility_outlined,
    'tmdb-10749' => Icons.favorite_border_rounded,
    'tmdb-10765' => Icons.rocket_launch_outlined,
    'tmdb-10766' => Icons.bubble_chart_outlined,
    'tmdb-10767' => Icons.forum_outlined,
    'tmdb-27' => Icons.mood_bad_outlined,
    'tmdb-53' => Icons.psychology_alt_outlined,
    'tmdb-10768' => Icons.policy_outlined,
    _ => Icons.movie_outlined,
  };

  Widget _genreCard(Map<String, dynamic> genre, double width) {
    final code = genre['codigo'] as String;
    final name = genre['nome'] as String;
    final selected = _selected.contains(code);
    final enabled = !_saving && (selected || _selected.length < 5);

    return SizedBox(
      width: width,
      child: Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        label: name,
        child: ExcludeSemantics(
          child: Opacity(
            opacity: enabled || selected ? 1 : 0.4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.16)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? AppTheme.primary
                      : Colors.white.withValues(alpha: 0.08),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: !enabled
                      ? null
                      : () {
                          setState(() {
                            _error = null;
                            if (selected) {
                              _selected.remove(code);
                            } else {
                              _selected.add(code);
                            }
                          });
                        },
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 19,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              Icon(
                                _genreIcon(code),
                                size: 30,
                                color: selected
                                    ? AppTheme.primary
                                    : Colors.white60,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: AnimatedOpacity(
                          opacity: selected ? 1 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(
                            Icons.check_circle,
                            size: 20,
                            color: AppTheme.primary,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: AppTheme.scaffoldBackground,
    child: PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 16, 4),
                    child: Row(
                      children: [
                        const Spacer(),
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.pop(context),
                          child: Text(
                            widget.isEditing ? 'Cancelar' : 'Escolher depois',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEditing
                                ? 'Seus gêneros\nfavoritos'
                                : 'Quais histórias\nvocê curte?',
                            style: const TextStyle(
                              fontSize: 32,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Escolha até 5 gêneros que você gosta de assistir.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _genres,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState !=
                                  ConnectionState.done) {
                                return const Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (snapshot.hasError) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Não foi possível carregar os gêneros.',
                                    ),
                                    TextButton(
                                      onPressed: () => setState(() {
                                        _genres = _loadGenres();
                                      }),
                                      child: const Text('Tentar novamente'),
                                    ),
                                  ],
                                );
                              }
                              final genres = snapshot.data ?? [];
                              if (genres.isEmpty) {
                                return const Text(
                                  'Nenhum gênero disponível no momento.',
                                );
                              }
                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  final columns = constraints.maxWidth < 240
                                      ? 1
                                      : 2;
                                  final width =
                                      (constraints.maxWidth -
                                          12 * (columns - 1)) /
                                      columns;
                                  return Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      for (final genre in genres)
                                        _genreCard(genre, width),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var index = 0; index < 5; index++)
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index < _selected.length
                                      ? AppTheme.primary
                                      : AppTheme.surfaceHighlight,
                                ),
                              ),
                            const SizedBox(width: 6),
                            Text(
                              '${_selected.length} de 5 selecionados',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed:
                                !_loaded ||
                                    _saving ||
                                    (!widget.isEditing && _selected.isEmpty)
                                ? null
                                : _save,
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.isEditing
                                            ? 'Salvar preferências'
                                            : 'Continuar',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
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
