// Avaliação feita pelo usuário para um filme ou série.
class Review {
  const Review({
    required this.content,
    required this.rating,
    required this.comment,
    required this.date,
  });

  final Map<String, String> content;
  final int rating;
  final String comment;
  final DateTime date;
}
