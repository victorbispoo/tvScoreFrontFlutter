import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'community_review_card.dart';

class CommunityReviewsSheet extends StatefulWidget {
  const CommunityReviewsSheet({
    super.key,
    required this.contentId,
    required this.type,
  });
  final int contentId;
  final String type;

  @override
  State<CommunityReviewsSheet> createState() => _CommunityReviewsSheetState();
}

class _CommunityReviewsSheetState extends State<CommunityReviewsSheet> {
  final _api = ApiService();
  final _reviews = <Map<String, dynamic>>[];
  int _nextPage = 0;
  int _totalPages = 1;
  int _total = 0;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading ||
        _nextPage >= _totalPages ||
        (_nextPage > 0 && _reviews.length >= _total)) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _api.getContentReviewsPage(
        widget.contentId,
        widget.type,
        page: _nextPage,
      );
      if (!mounted) return;
      setState(() {
        final ids = _reviews.map((review) => review['id']).toSet();
        _reviews.addAll(page.reviews.where((review) => ids.add(review['id'])));
        _totalPages = page.totalPages;
        _total = page.totalElements;
        _nextPage++;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível carregar as avaliações.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: .73,
    minChildSize: .4,
    maxChildSize: .95,
    expand: false,
    builder: (context, controller) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          top: false,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.depth == 0 &&
                  notification.metrics.extentAfter < 300 &&
                  _error == null &&
                  !_loading) {
                // Scroll notifications arrive during layout; request after the frame.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _loadMore();
                });
              }
              return false;
            },
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: _reviews.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Avaliações da comunidade',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _nextPage == 0
                            ? 'Carregando avaliações…'
                            : '$_total ${_total == 1 ? 'avaliação' : 'avaliações'}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }
                if (index <= _reviews.length) {
                  return CommunityReviewCard.fromJson(
                    _reviews[index - 1],
                    preview: false,
                  );
                }
                if (_loading) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (_error != null) {
                  return Column(
                    children: [
                      Text(_error!),
                      TextButton(
                        onPressed: _loadMore,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  );
                }
                if (_reviews.isEmpty) {
                  return const Text(
                    'Ainda não há avaliações para este título.',
                  );
                }
                if (_nextPage < _totalPages && _reviews.length < _total) {
                  return TextButton(
                    onPressed: _loadMore,
                    child: const Text('Carregar mais avaliações'),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    ),
  );
}
