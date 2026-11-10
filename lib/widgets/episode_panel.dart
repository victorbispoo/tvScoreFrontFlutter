import 'package:flutter/material.dart';

import '../services/api_services.dart';
import 'episode_ratings_grid.dart';

class EpisodePanel extends StatefulWidget {
  const EpisodePanel({super.key, required this.seriesId});

  final int seriesId;

  @override
  State<EpisodePanel> createState() => _EpisodePanelState();
}

class _EpisodePanelState extends State<EpisodePanel> {
  final _api = ApiService();
  late Future<Map<String, dynamic>> _panel;

  @override
  void initState() {
    super.initState();
    _panel = _api.getEpisodePanel(widget.seriesId);
  }

  @override
  void didUpdateWidget(covariant EpisodePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seriesId != widget.seriesId) {
      _panel = _api.getEpisodePanel(widget.seriesId);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _panel,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const LinearProgressIndicator();
      }
      if (snapshot.hasError) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Não foi possivel carregar os episódios'),
            TextButton(
              onPressed: () => setState(() {
                _panel = _api.getEpisodePanel(widget.seriesId);
              }),
              child: const Text('Tentar Novamente'),
            ),
          ],
        );
      }
      return EpisodeRatingsGrid(
        key: ValueKey(widget.seriesId),
        seasons: (snapshot.data?['temporadas'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
      );
    },
  );
}
