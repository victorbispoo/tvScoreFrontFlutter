import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

class CommunityReviewCard extends StatelessWidget {
  const CommunityReviewCard({
    super.key,
    required this.author,
    required this.rating,
    required this.comment,
  });

  final String? author;
  final double rating;
  final String comment;

  @override
  Widget build(BuildContext context) {
    final author = this.author;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    author == null || author.trim().isEmpty
                        ? 'Usuário'
                        : author,
                  ),
                ),
                SizedBox(width: 8),
                Text('•'),
                SizedBox(width: 8),
                const Icon(HugeIconsSolid.star, color: Colors.amber, size: 14),
                SizedBox(width: 5),
                Text('${rating.toStringAsFixed(1)}/10'),
              ],
            ),
            if (comment.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(comment),
            ],
          ],
        ),
      ),
    );
  }
}
