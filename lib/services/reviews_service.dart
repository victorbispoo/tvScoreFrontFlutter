part of 'api_services.dart';

extension ReviewsService on ApiService {
  Review? reviewFor(Map<String, String> content) {
    for (final review in ApiService.reviews) {
      if (review.content['id'] == content['id'] &&
          review.content['type'] == content['type']) {
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
    final contentId = int.tryParse(content['id'] ?? '');
    final contentType = content['type'];
    if(contentId==null || contentId <= 0){
      throw ArgumentError('ID do conteúdo inválido.');
    }
    if(contentType != 'movie' && contentType != 'tv'){
      throw ArgumentError('Tipo de conteúdo inválido.');
    }

    final token = ApiService.token;
    if (token == null || token.isEmpty) {
      throw StateError('Entre na sua conta pra avaliar');
    }

    final response = await dio.post(
      '/avaliacoes',
      data: {
        'filmeSerieId': contentId,
        'tipoConteudo': contentType == 'movie' ? 'MOVIE' : 'TV',
        'nota': rating,
        'comentario': comment.trim(),
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    final data = Map<String, dynamic>.from(response.data as Map);

    final savedReview = Review(
      id: data['id'] as int,
      content: content,
      rating: data['nota'] as int,
      comment: data['comentario'] as String,
      date: DateTime.parse(data['data'] as String),
    );

    final updatedReviews = List<Review>.from(ApiService.reviews);
    updatedReviews.removeWhere(
      (review) =>
          review.content['id'] == content['id'] &&
          review.content['type'] == content['type'],
    );
    updatedReviews.add(savedReview);
    ApiService.reviews = updatedReviews;
  }

  Future<void> deleteReview(Review review) async {
    final id = review.id;
    if (id == null || id <= 0) {
      throw ArgumentError('ID da avaliação inválido.');
    }

    final token = ApiService.token;
    if (token == null || token.isEmpty) {
      throw StateError('Entre na sua conta pra remover a avaliação');
    }

    await dio.delete(
      '/avaliacoes/$id',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    ApiService.reviews = ApiService.reviews
    .where((item) => item.id != id)
    .toList();
  }
}
