// Avaliação feita pelo usuário para um filme ou série.
class Review {
  const Review({
    this.id,
    required this.content,
    required this.rating,
    required this.comment,
    required this.date,
  });
  final int? id;
  final Map<String, String> content;
  final double rating;
  final String comment;
  final DateTime date;

  factory Review.fromJson(
    Map<String, dynamic> data,
    Map<String, String> content,
  ) => Review(
    id: (data['id'] as num).toInt(),
    content: content,
    rating: (data['nota'] as num).toDouble(),
    comment: data['comentario'] as String? ?? '',
    date: DateTime.parse(data['dataCriacao'] as String),
  );
}
