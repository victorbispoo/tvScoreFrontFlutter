part of 'api_services.dart';

extension ReviewsService on ApiService {
  Future<List<Map<String, dynamic>>> getMyReviews() async {
    final session = ApiService._sessionVersion;
    final token = ApiService.token;
    if (token == null || token.isEmpty) {
      throw StateError('Entre na sua conta para consultar avaliações.');
    }

    final response = await dio.get(
      '/avaliacoes/minhas',
      options: _authorizationOptions,
    );

    ApiService._checkSession(session);
    final items = response.data as List;
    return items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getContentReviews(
    int contentId,
    String type,
  ) async {
    requireContentReference(contentId, type);

    final response = await dio.get(
      '/avaliacoes/filme/$contentId',
      queryParameters: {'tipoConteudo': type},
      options: _authorizationOptions,
    );

    final items = response.data as List;
    return items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> getContentReviewSummary(
    int contentId,
    String type,
  ) async {
    requireContentReference(contentId, type);

    final response = await dio.get(
      '/avaliacoes/conteudo/$contentId/resumo',
      queryParameters: {'tipoConteudo': type},
      options: _authorizationOptions,
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> loadMyReviews() async {
    final session = ApiService._sessionVersion;
    final items = await getMyReviews();

    final loadedReviews = await Future.wait(
      items.map((item) async {
        final contentId = (item['filmeSerieId'] as num).toInt();

        final type = item['tipoConteudo'] as String;
        final content = await getContent(contentId, type);

        return Review.fromJson(item, content);
      }),
    );
    ApiService._checkSession(session);
    ApiService.reviews = loadedReviews;
  }

  Future<void> loadMyReviewFor(Map<String, String> content) async {
    final session = ApiService._sessionVersion;
    final reference = content.apiReference;
    final items = await getMyReviews();

    Review? found;

    for (final item in items) {
      final sameContent =
          (item['filmeSerieId'] as num).toInt() == reference.id &&
          item['tipoConteudo'] == reference.type;

      if (sameContent) {
        found = Review.fromJson(item, content);
        break;
      }
    }
    ApiService._checkSession(session);
    _replaceReviewFor(content, found);
  }

  void _replaceReviewFor(Map<String, String> content, Review? review) {
    final updated = List<Review>.from(ApiService.reviews)
      ..removeWhere((item) => item.content.contentKey == content.contentKey);
    if (review != null) updated.add(review);
    ApiService.reviews = updated;
  }

  Review? reviewFor(Map<String, String> content) {
    for (final review in ApiService.reviews) {
      if (review.content.contentKey == content.contentKey) {
        return review;
      }
    }
    return null;
  }

  Future<void> saveReview(
    Map<String, String> content,
    double rating,
    String comment,
  ) async {
    final session = ApiService._sessionVersion;
    if (!Review.isValidRating(rating)) {
      throw ArgumentError('A nota deve ser de 0 a 10.');
    }
    final reference = content.apiReference;

    final token = ApiService.token;
    if (token == null || token.isEmpty) {
      throw StateError('Entre na sua conta pra avaliar');
    }

    final response = await dio.post(
      '/avaliacoes',
      data: {
        'filmeSerieId': reference.id,
        'tipoConteudo': reference.type,
        'nota': rating,
        'comentario': comment.trim(),
      },
      options: _authorizationOptions,
    );

    ApiService._checkSession(session);
    final data = Map<String, dynamic>.from(response.data as Map);

    final savedReview = Review.fromJson(data, content);

    _replaceReviewFor(content, savedReview);
  }

  Future<void> deleteReview(Review review) async {
    final session = ApiService._sessionVersion;
    final id = review.id;
    if (id == null || id <= 0) {
      throw ArgumentError('ID da avaliação inválido.');
    }

    final token = ApiService.token;
    if (token == null || token.isEmpty) {
      throw StateError('Entre na sua conta pra remover a avaliação');
    }

    await dio.delete('/avaliacoes/$id', options: _authorizationOptions);

    ApiService._checkSession(session);
    ApiService.reviews = ApiService.reviews
        .where((item) => item.id != id)
        .toList();
  }
}
