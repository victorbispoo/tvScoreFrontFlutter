import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'tv_score_snackbar.dart';

class WhereToWatch extends StatelessWidget {
  WhereToWatch(String? availability, {super.key})
    : _data = availability == null
          ? const {}
          : jsonDecode(availability) as Map<String, dynamic>;

  final Map<String, dynamic> _data;

  static const _links = {
    'netflix': 'https://www.netflix.com/br/',
    'netflix standard with ads': 'https://www.netflix.com/br/',
    'amazon prime video': 'https://www.primevideo.com/',
    'amazon prime video with ads': 'https://www.primevideo.com/',
    'amazon video': 'https://www.primevideo.com/',
    'disney plus': 'https://www.disneyplus.com/pt-br',
    'hbo max': 'https://www.hbomax.com/br/pt',
    'max': 'https://www.hbomax.com/br/pt',
    'globoplay': 'https://globoplay.globo.com/',
    'paramount plus': 'https://www.paramountplus.com/br/',
    'apple tv': 'https://tv.apple.com/br',
    'apple tv plus': 'https://tv.apple.com/br',
    'crunchyroll': 'https://www.crunchyroll.com/pt-br',
  };

  static String _normalize(String name) =>
      name.trim().toLowerCase().replaceAll('+', ' plus').replaceAll('  ', ' ');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final providers = <String, Map<String, dynamic>>{};
    for (final category in const [
      'assinatura',
      'gratis',
      'comAnuncios',
      'aluguel',
      'compra',
    ]) {
      if (_data[category] case final List entries) {
        for (final entry in entries.whereType<Map<String, dynamic>>()) {
          if (entry['provider_name'] case final String name
              when name.trim().isNotEmpty) {
            final key = _normalize(name);
            providers.putIfAbsent(_links[key] ?? key, () => entry);
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Onde assistir',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Disponibilidade no Brasil',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        if (providers.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Disponibilidade não informada para o Brasil',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
        if (providers.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final provider in providers.values)
                  _provider(context, provider),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _provider(BuildContext context, Map<String, dynamic> provider) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final name = provider['provider_name'] as String;
    final url = _links[_normalize(name)];
    final logo = provider['logo_path'];
    final fallback = Icon(
      Icons.live_tv_outlined,
      color: colors.onSurfaceVariant,
    );
    return Tooltip(
      message: name,
      excludeFromSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: url == null
            ? null
            : () async {
                try {
                  if (await launchUrl(Uri.parse(url))) return;
                } catch (_) {
                  // The platform may not have an app that handles this URL.
                }
                if (context.mounted) {
                  TvScoreSnackbar.error(
                    context,
                    'Não foi possível abrir $name.',
                  );
                }
              },
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: logo is String && RegExp(r'^/[\w.-]+$').hasMatch(logo)
                    ? Image.network(
                        'https://image.tmdb.org/t/p/w92$logo',
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) => fallback,
                      )
                    : fallback,
              ),
              const SizedBox(height: 4),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
