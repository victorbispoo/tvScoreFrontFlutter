// Avaliação feita pelo usuário para um filme ou série.
class Review {
  const Review({
    required this.movie,
    required this.rating,
    required this.comment,
    required this.date,
  });

  final Map<String, String> movie;
  final int rating;
  final String comment;
  final DateTime date;
}
