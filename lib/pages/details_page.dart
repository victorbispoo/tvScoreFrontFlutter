import 'package:flutter/material.dart';

import '../services/api_services.dart';
import '../widgets/movie_card.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key, required this.movie});
  final Map<String, String> movie;

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final _api = ApiService();
  late final TextEditingController _comment;
  late int _rating;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final review = _api.reviewFor(widget.movie);
    _rating = review?.rating ?? 8;
    _comment = TextEditingController(text: review?.comment ?? '');
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _toggleSaved() async {
    setState(() => _busy = true);
    try {
      await _api.toggleSaved(widget.movie);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sua lista foi atualizada.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar sua lista.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveReview() async {
    setState(() => _busy = true);
    try {
      await _api.saveReview(widget.movie, _rating, _comment.text);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Avaliação salva!')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a avaliação.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final saved = _api.isSaved(movie);
    final review = _api.reviewFor(movie);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: SizedBox(
                width: 200,
                height: 290,
                child: MoviePoster(movie: movie),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              movie['title']!,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${movie['year']} • ${movie['genre']}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber),
                const SizedBox(width: 6),
                Text('${movie['score']} / 10 no catálogo'),
              ],
            ),
            if (movie['overview'] != null) ...[
              const SizedBox(height: 20),
              Text(movie['overview']!, style: const TextStyle(height: 1.6)),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _busy ? null : _toggleSaved,
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
              label: Text(
                saved ? 'Remover da minha lista' : 'Adicionar à minha lista',
              ),
            ),
            const SizedBox(height: 28),
            Text(
              review == null ? 'Sua avaliação' : 'Editar sua avaliação',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Sua nota: $_rating / 10',
              style: const TextStyle(color: Colors.amber, fontSize: 18),
            ),
            Slider(
              value: _rating.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_rating',
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _rating = value.round()),
            ),
            TextField(
              controller: _comment,
              enabled: !_busy,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Comentário (opcional)',
                hintText: 'O que você achou desse título?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _saveReview,
              icon: const Icon(Icons.star_outline),
              label: Text(_busy ? 'Salvando...' : 'Salvar avaliação'),
            ),
          ],
        ),
      ),
    );
  }
}
