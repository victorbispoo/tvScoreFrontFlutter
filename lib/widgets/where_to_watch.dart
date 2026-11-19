import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_breakpoints.dart';
import 'tv_score_snackbar.dart';

typedef _Provider = ({String name, String? logo});

class WhereToWatch extends StatelessWidget {
  static const _previewSize = 48.0;
  static final _tileRadius = BorderRadius.circular(10);

  factory WhereToWatch(String? availability, {Key? key}) {
    Object? decoded;
    try {
      decoded = availability == null ? null : jsonDecode(availability);
    } on FormatException {
      decoded = null;
    }
    final data = decoded is Map<String, dynamic> ? decoded : const {};
    final groups = <String, List<_Provider>>{};
    final summary = <Object, _Provider>{};
    for (final category in _categories.keys) {
      if (data[category] case final List entries) {
        final providers = <Object, _Provider>{};
        for (final entry in entries.whereType<Map<String, dynamic>>()) {
          final name = entry['provider_name'];
          if (name is! String || name.trim().isEmpty) continue;
          final id = entry['provider_id'];
          final logo = entry['logo_path'];
          final provider = (
            name: name.trim(),
            logo: logo is String && _logoPath.hasMatch(logo) ? logo : null,
          );
          final identity = id is int ? id : provider.name.toLowerCase();
          providers.putIfAbsent(identity, () => provider);
          summary.putIfAbsent(identity, () => provider);
        }
        if (providers.isNotEmpty) groups[category] = providers.values.toList();
      }
    }
    final rawLink = data['link'];
    final uri = rawLink is String ? Uri.tryParse(rawLink.trim()) : null;
    final link =
        uri != null &&
            uri.host.isNotEmpty &&
            (uri.scheme == 'https' || uri.scheme == 'http')
        ? uri
        : null;
    return WhereToWatch._(groups, summary.values.toList(), link, key: key);
  }

  const WhereToWatch._(this._groups, this._providers, this._link, {super.key});

  static const _categories = {
    'assinatura': ('Assinatura', 'Disponível por assinatura'),
    'gratis': ('Grátis', 'Disponível grátis'),
    'comAnuncios': ('Com anúncios', 'Disponível com anúncios'),
    'aluguel': ('Aluguel', 'Disponível para aluguel'),
    'compra': ('Compra', 'Disponível para compra'),
  };
  static final _logoPath = RegExp(
    r'^/[\w.-]+\.(png|jpe?g|webp)$',
    caseSensitive: false,
  );

  final Map<String, List<_Provider>> _groups;
  final List<_Provider> _providers;
  final Uri? _link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final additional = _providers.length - 3;
    final secondary = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Onde assistir',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            Text('Brasil', style: secondary),
          ],
        ),
        if (_providers.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Disponibilidade não informada para o Brasil',
              style: secondary,
            ),
          )
        else ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final provider in _providers.take(3))
                Tooltip(
                  message: provider.name,
                  child: _logo(context, provider, _previewSize),
                ),
              if (additional > 0)
                Tooltip(
                  message: 'Ver todos os provedores',
                  excludeFromSemantics: true,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      fixedSize: const Size.square(_previewSize),
                      minimumSize: const Size.square(_previewSize),
                      padding: EdgeInsets.zero,
                      backgroundColor: colors.surfaceContainerLow,
                      foregroundColor: colors.onSurface,
                      side: BorderSide(color: colors.outlineVariant),
                      shape: RoundedRectangleBorder(borderRadius: _tileRadius),
                    ),
                    onPressed: () => _showOptions(context),
                    child: Text(
                      '+$additional',
                      semanticsLabel:
                          'Ver todos os provedores. Mais $additional',
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (_groups.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_categories[_groups.keys.first]!.$2, style: secondary),
          ),
      ],
    );
  }

  Future<void> _showOptions(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    constraints:
        AppBreakpoints.supportsWidePages &&
            AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width)
        ? const BoxConstraints(maxWidth: 600, maxHeight: 700)
        : null,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: [
            Text(
              'Onde assistir no Brasil',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final entry in _groups.entries) ...[
              const SizedBox(height: 16),
              Text(
                _categories[entry.key]!.$1,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final provider in entry.value)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _logo(context, provider, 44),
                  title: Text(provider.name),
                ),
            ],
            if (_link case final link?)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () async {
                    try {
                      if (await launchUrl(
                        link,
                        mode: LaunchMode.externalApplication,
                      )) {
                        return;
                      }
                    } catch (_) {
                      // An external handler may not be available.
                    }
                    if (context.mounted) {
                      TvScoreSnackbar.error(
                        context,
                        'Não foi possível abrir o link.',
                      );
                    }
                  },
                  child: const Text('Ver disponibilidade no TMDB'),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _logo(BuildContext context, _Provider provider, double size) {
    final colors = Theme.of(context).colorScheme;
    final logo = provider.logo;
    final fallback = Icon(
      Icons.live_tv_outlined,
      color: colors.onSurfaceVariant,
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: _tileRadius,
      ),
      child: logo != null
          ? Image.network(
              'https://image.tmdb.org/t/p/w92$logo',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => fallback,
            )
          : fallback,
    );
  }
}
