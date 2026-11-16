import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '../core/app_theme.dart';
import '../core/rating_scale.dart';
import 'user_avatar.dart';

class CommunityReviewCard extends StatefulWidget {
  const CommunityReviewCard({
    super.key,
    required this.author,
    required this.rating,
    required this.comment,
    this.date,
    this.photoUrl,
    this.preview = true,
  });

  factory CommunityReviewCard.fromJson(
    Map<String, dynamic> review, {
    bool preview = true,
  }) => CommunityReviewCard(
    key: ValueKey(review['id']),
    author: review['nomeUsuario'] as String?,
    photoUrl: review['fotoUsuarioUrl'] as String?,
    rating: (review['nota'] as num).toDouble(),
    comment: review['comentario'] as String? ?? '',
    date: DateTime.tryParse(review['dataCriacao'] as String? ?? ''),
    preview: preview,
  );

  final String? author;
  final String? photoUrl;
  final double rating;
  final String comment;
  final DateTime? date;
  final bool preview;

  @override
  State<CommunityReviewCard> createState() => _CommunityReviewCardState();
}

class _CommunityReviewCardState extends State<CommunityReviewCard> {
  bool _expanded = false;

  String _dateLabel(DateTime date) {
    const months = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final author = widget.author?.trim();
    final color = RatingScale.color(widget.rating);
    return Card(
      color: AppTheme.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(name: author, imageUrl: widget.photoUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author == null || author.isEmpty ? 'Usuário' : author,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (widget.date != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _dateLabel(widget.date!),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(HugeIconsSolid.star, size: 14, color: color),
                      Text(
                        '${widget.rating.toStringAsFixed(1)}/10',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.comment.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final style = DefaultTextStyle.of(
                    context,
                  ).style.copyWith(color: Colors.white70, height: 1.5);
                  final painter = TextPainter(
                    text: TextSpan(text: widget.comment, style: style),
                    maxLines: 4,
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                  )..layout(maxWidth: constraints.maxWidth);
                  final overflows = painter.didExceedMaxLines;
                  painter.dispose();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.comment,
                        style: style,
                        maxLines: widget.preview && !_expanded ? 4 : null,
                        overflow: widget.preview && !_expanded
                            ? TextOverflow.ellipsis
                            : null,
                      ),
                      if (widget.preview && overflows)
                        TextButton(
                          onPressed: () =>
                              setState(() => _expanded = !_expanded),
                          child: Text(_expanded ? 'Ler menos' : 'Ler mais'),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
