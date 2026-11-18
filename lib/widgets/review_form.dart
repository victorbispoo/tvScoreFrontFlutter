import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../core/rating_scale.dart';
import '../models/review.dart';

class ReviewForm extends StatelessWidget {
  const ReviewForm({
    super.key,
    required this.isEditing,
    required this.rating,
    required this.commentController,
    required this.enabled,
    required this.isSaving,
    required this.onRatingChanged,
    required this.onSave,
  });
  final bool isEditing;
  final double rating;
  final TextEditingController commentController;
  final bool enabled;
  final bool isSaving;
  final ValueChanged<double> onRatingChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        !isEditing ? 'Sua avaliação' : 'Editar sua avaliação',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 20),
      Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Theme.of(context).brightness == Brightness.light
                ? 252
                : 280,
          ),
          child: Row(
            children: [
              IconButton.outlined(
                tooltip: 'Diminuir nota',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: enabled && !isSaving && rating > Review.minRating
                    ? () => onRatingChanged(
                        (rating - .5)
                            .clamp(Review.minRating, Review.maxRating)
                            .toDouble(),
                      )
                    : null,
                icon: const Icon(HugeIconsStroke.minusSign, size: 20),
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  label:
                      'Sua nota: ${rating.toStringAsFixed(1)} de 10. ${RatingScale.label(rating)}',
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 180),
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w600,
                                  color: RatingScale.color(rating),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: Text(
                                    rating.toStringAsFixed(1),
                                    key: ValueKey(rating),
                                  ),
                                ),
                              ),
                              Text(
                                '/10',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          style: TextStyle(
                            color: RatingScale.color(rating),
                            fontWeight: FontWeight.w500,
                          ),
                          child: Text(
                            RatingScale.label(rating),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton.outlined(
                tooltip: 'Aumentar nota',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: enabled && !isSaving && rating < Review.maxRating
                    ? () => onRatingChanged(
                        (rating + .5)
                            .clamp(Review.minRating, Review.maxRating)
                            .toDouble(),
                      )
                    : null,
                icon: const Icon(HugeIconsStroke.add01, size: 20),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: commentController,
        builder: (context, value, _) => Row(
          children: [
            Expanded(
              child: Text(
                'Comentário (opcional)',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.text.characters.length}/500',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: commentController,
        enabled: enabled && !isSaving,
        minLines: 3,
        maxLines: 6,
        maxLength: 500,
        buildCounter:
            (
              _, {
              required currentLength,
              required isFocused,
              required maxLength,
            }) => null,
        decoration: InputDecoration(
          fillColor: Theme.of(context).brightness == Brightness.light
              ? Theme.of(context).colorScheme.surface
              : null,
          hintText: 'O que você achou desse título?',
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: !enabled || isSaving ? null : onSave,
          icon: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(HugeIconsStroke.checkmarkCircle01, size: 18),
          label: Text(
            isSaving
                ? 'Salvando...'
                : isEditing
                ? 'Atualizar avaliação'
                : 'Publicar avaliação',
          ),
        ),
      ),
    ],
  );
}
