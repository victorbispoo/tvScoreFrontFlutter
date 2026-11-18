import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../models/content_metadata.dart';
import '../services/api_services.dart';
import 'preferred_content_picker.dart';

class ContentPreferencesDialog extends StatefulWidget {
  const ContentPreferencesDialog({super.key, this.isEditing = false});
  final bool isEditing;

  @override
  State<ContentPreferencesDialog> createState() =>
      _ContentPreferencesDialogState();
}

class _ContentPreferencesDialogState extends State<ContentPreferencesDialog> {
  final _api = ApiService();
  final _selected = <String>{};
  final _contents = <(String?, String?), Map<String, String>>{};
  final _sessionToken = ApiService.token;
  late Future<List<Map<String, dynamic>>> _genres;
  Set<String>? _confirmedGenres;
  int _step = 0;
  bool _visitedContents = false;
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
    final (genres, preferred, contents) = await (
      _api.getAvailableGenres(),
      widget.isEditing
          ? _api.getPreferredGenres()
          : Future.value(<Map<String, dynamic>>[]),
      widget.isEditing
          ? _api.getPreferredContents()
          : Future.value(<Map<String, String>>[]),
    ).wait;
    if (mounted) {
      setState(() {
        _selected
          ..clear()
          ..addAll(preferred.map((genre) => genre['codigo'] as String));
        _contents
          ..clear()
          ..addEntries(contents.map((item) => MapEntry(item.contentKey, item)));
        _loaded = true;
      });
    }
    return genres;
  }

  void _checkSession() {
    if (_sessionToken == null || ApiService.token != _sessionToken) {
      throw StateError('A sessão mudou. Reabra as preferências.');
    }
  }

  Future<void> _save() async {
    if (_saving || !_loaded || _step != 1) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    var savingContents = false;
    try {
      _checkSession();
      if (_confirmedGenres == null || !setEquals(_confirmedGenres, _selected)) {
        await _api.savePreferredGenres(_selected.toList());
        _confirmedGenres = Set.of(_selected);
      }
      _checkSession();
      savingContents = true;
      await _api.savePreferredContents(_contents.values.toList());
      _checkSession();
      ApiService.contentPreferencesRevision.value++;
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = savingContents
              ? 'Os gêneros foram salvos. Não foi possível confirmar os filmes e séries. Tente concluir novamente.'
              : 'Não foi possível confirmar os gêneros. O envio dos filmes e séries não foi iniciado. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancel() async {
    if (_saving) return;
    if (_confirmedGenres != null) {
      final close = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Gravação incompleta'),
          content: const Text(
            'Os gêneros já foram salvos. Os filmes e séries não foram confirmados. Fechar não desfaz essa gravação.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuar editando'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
      if (close != true) return;
    }
    if (mounted) Navigator.pop(context);
  }

  void _back() => setState(() {
    _step = 0;
    _error = null;
  });

  Widget _genreList() => FutureBuilder<List<Map<String, dynamic>>>(
    future: _genres,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        );
      }
      if (snapshot.hasError) {
        return Column(
          children: [
            const Text('Não foi possível carregar as preferências.'),
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
      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 240 ? 1 : 2;
          final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [for (final genre in genres) _genreCard(genre, width)],
          );
        },
      );
    },
  );

  Widget _heading() => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Etapa ${_step + 1} de 2',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: Theme.of(context).brightness == Brightness.light
                ? FontWeight.w600
                : null,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_step + 1) / 2,
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          _step == 0
              ? (widget.isEditing
                    ? 'Seus gêneros\nfavoritos'
                    : 'Quais histórias\nvocê curte?')
              : 'Seus filmes e séries\npreferidos',
          style: const TextStyle(
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _step == 0
              ? 'Escolha até 5 gêneros que você gosta de assistir.'
              : 'Escolha até 5 filmes e séries no total.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final count = _step == 0 ? _selected.length : _contents.length;
    return Dialog.fullscreen(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !_saving) {
            if (_step == 1) {
              _back();
            } else {
              _cancel();
            }
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      _step == 1 && MediaQuery.sizeOf(context).width >= 900
                      ? 760
                      : 520,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          if (_step == 1)
                            IconButton(
                              tooltip: 'Voltar aos gêneros',
                              onPressed: _saving ? null : _back,
                              icon: const Icon(HugeIconsStroke.arrowLeft01),
                            ),
                          const Spacer(),
                          TextButton(
                            onPressed: _saving ? null : _cancel,
                            child: Text(
                              widget.isEditing ? 'Cancelar' : 'Escolher depois',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AbsorbPointer(
                        absorbing: _saving,
                        child: IndexedStack(
                          index: _step,
                          children: [
                            SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              child: Column(
                                children: [_heading(), _genreList()],
                              ),
                            ),
                            if (_visitedContents)
                              PreferredContentPicker(
                                header: _heading(),
                                selected: _contents,
                                onChanged: () => setState(() {}),
                              )
                            else
                              const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? Theme.of(context).colorScheme.outlineVariant
                                : Colors.white.withValues(alpha: .06),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          ExcludeSemantics(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var index = 0; index < 5; index++)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: index < count
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$count de 5 selecionados',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          if (_error != null || _confirmedGenres != null) ...[
                            const SizedBox(height: 10),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _error ??
                                    'Gêneros já salvos. Conclua para confirmar os filmes e séries.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: !_loaded || _saving
                                  ? null
                                  : _step == 1
                                  ? _save
                                  : () => setState(() {
                                      _step = 1;
                                      _visitedContents = true;
                                    }),
                              child: _saving
                                  ? SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    )
                                  : Text(_step == 0 ? 'Continuar' : 'Concluir'),
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
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.16)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).colorScheme.outlineVariant
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
                                genreIcon(code),
                                size: 30,
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
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
      ),
    );
  }
}

IconData genreIcon(String code) => switch (code) {
  'tmdb-10759' => HugeIconsSolid.adventure,
  'tmdb-12' => HugeIconsSolid.compass01,
  'tmdb-28' => HugeIconsSolid.sword01,
  'tmdb-10770' => HugeIconsSolid.tv01,
  'animacao' => HugeIconsSolid.magicWand01,
  'comedia' => HugeIconsSolid.game,
  'crime' => HugeIconsSolid.policeBadge,
  'documentario' => HugeIconsSolid.globe02,
  'drama' => HugeIconsSolid.bookOpen01,
  'familia' => HugeIconsSolid.favourite,
  'tmdb-14' => HugeIconsSolid.magicWand01,
  'tmdb-878' => HugeIconsSolid.alien01,
  'tmdb-10752' => HugeIconsSolid.shield01,
  'tmdb-36' => HugeIconsSolid.book01,
  'tmdb-10762' => HugeIconsSolid.baby01,
  'misterio' => HugeIconsSolid.search01,
  'faroeste' => HugeIconsSolid.mountain,
  'tmdb-10402' => HugeIconsSolid.musicNote01,
  'tmdb-10763' => HugeIconsSolid.globe02,
  'tmdb-10764' => HugeIconsSolid.view,
  'tmdb-10749' => HugeIconsSolid.favourite,
  'tmdb-10765' => HugeIconsSolid.rocket01,
  'tmdb-10766' => HugeIconsSolid.bubbleChat,
  'tmdb-10767' => HugeIconsSolid.chat01,
  'tmdb-27' => HugeIconsSolid.fire,
  'tmdb-53' => HugeIconsSolid.brain,
  'tmdb-10768' => HugeIconsSolid.shield01,
  _ => HugeIconsSolid.film01,
};
