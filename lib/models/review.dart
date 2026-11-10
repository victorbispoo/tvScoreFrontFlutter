class Review {
  static const minRating = 0.0;
  static const maxRating = 10.0;
  static const ratingDivisions = 20;

  static bool isValidRating(double value) =>
      value.isFinite && value >= minRating && value <= maxRating;

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
