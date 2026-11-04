part of 'api_services.dart';

extension ReviewsService on ApiService {
  Review? reviewFor(Map<String, String> content) {
    for (final review in ApiService.reviews) {
      if (review.content['title'] == content['title']) {
        return review;
      }
    }
    return null;
  }

  Future<void> saveReview(
    Map<String, String> content,
    int rating,
    String comment,
  ) async {
    if (rating < 1 || rating > 10) {
      throw ArgumentError('A nota deve ser de 1 a 10.');
    }
    final contentReviews = List<Review>.from(ApiService.reviews);
    contentReviews.removeWhere(
      (review) => review.content['title'] == content['title'],
    );
    contentReviews.add(
      Review(
        content: content,
        rating: rating,
        comment: comment.trim(),
        date: DateTime.now(),
      ),
    );
    await _saveLibrary(
      ApiService.savedContents,
      contentReviews,
      ApiService.userName,
    );
  }

  Future<void> deleteReview(Review review) async {
    final contentReviews = List<Review>.from(ApiService.reviews);
    contentReviews.removeWhere(
      (item) => item.content['title'] == review.content['title'],
    );
    await _saveLibrary(
      ApiService.savedContents,
      contentReviews,
      ApiService.userName,
    );
  }
}
