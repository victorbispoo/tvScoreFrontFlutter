import 'package:flutter/material.dart';

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
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        'Sua nota: $rating / 10',
        style: const TextStyle(color: Colors.amber, fontSize: 18),
      ),
      Slider(
        value: rating,
        min: 0,
        max: 10,
        divisions: 20,
        label: '$rating',
        onChanged: enabled ? onRatingChanged : null,
      ),
      TextField(
        controller: commentController,
        enabled: enabled,
        maxLines: 4,
        maxLength: 500,
        decoration: const InputDecoration(
          labelText: 'Comentário (opcional)',
          hintText: 'O que você achou desse título?',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: !enabled ? null : onSave,
        icon: const Icon(Icons.star_outline),
        label: Text(isSaving ? 'Salvando...' : 'Salvar avaliação'),
      ),
    ],
  );
}
