part of 'api_services.dart';

extension ReviewsService on ApiService {
  Review? reviewFor(Map<String, String> movie) {
    for (final review in ApiService.reviews) {
      if (review.movie['title'] == movie['title']) {
        return review;
      }
    }
    return null;
  }

  Future<void> saveReview(
    Map<String, String> movie,
    int rating,
    String comment,
  ) async {
    if (rating < 1 || rating > 10) {
      throw ArgumentError('A nota deve ser de 1 a 10.');
    }
    final movieReviews = List<Review>.from(ApiService.reviews);
    movieReviews.removeWhere(
      (review) => review.movie['title'] == movie['title'],
    );
    movieReviews.add(
      Review(
        movie: movie,
        rating: rating,
        comment: comment.trim(),
        date: DateTime.now(),
      ),
    );
    await _saveLibrary(
      ApiService.savedMovies,
      movieReviews,
      ApiService.userName,
    );
  }

  Future<void> deleteReview(Review review) async {
    final movieReviews = List<Review>.from(ApiService.reviews);
    movieReviews.removeWhere(
      (item) => item.movie['title'] == review.movie['title'],
    );
    await _saveLibrary(
      ApiService.savedMovies,
      movieReviews,
      ApiService.userName,
    );
  }
}
