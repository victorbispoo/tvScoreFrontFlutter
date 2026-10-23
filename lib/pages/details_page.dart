import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../services/api_services.dart';

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
    final backdrop = movie['backdrop_path'];
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final saved = _api.isSaved(movie);
    final review = _api.reviewFor(movie);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,

      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Center(
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 280+ (MediaQuery.of(context).padding.top),
                    child: Image.network(
                      backdrop ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            backgroundColor.withValues(alpha: 0.05),
                            backgroundColor.withValues(alpha: 0.15),
                            backgroundColor.withValues(alpha: 0.45),
                            backgroundColor.withValues(alpha: 0.8),
                            backgroundColor.withValues(alpha: 0.9),
                            backgroundColor,
                          ],
                          stops: const [0, 0.3, 0.55, 0.78, 0.90, 0.95],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Text(
                      movie['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${movie['year']}  •  ${movie['genre']}  •  ',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const Icon(
                        HugeIconsSolid.star,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text('${movie['score']}'),
                    ],
                  ),
                  if (movie['overview'] != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      movie['overview']!,
                      style: const TextStyle(height: 1.6),
                    ),
                  ],
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _toggleSaved,
                    icon: Icon(
                      saved
                          ? HugeIconsSolid.favourite
                          : HugeIconsStroke.favourite,
                    ),
                    label: Text(
                      saved
                          ? 'Remover dos favoritos'
                          : 'Adicionar aos favoritos',
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    review == null ? 'Sua avaliação' : 'Editar sua avaliação',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
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
          ],
        ),
      ),
    );
  }
}
