part of 'api_services.dart';

extension ReviewsService on ApiService {
  Future<List<Map<String, dynamic>>> getMyReviews() async {
    final token = ApiService.token;
    if (token == null || token.isEmpty) {
      throw StateError('Entre na sua conta para consultar avaliações.');
    }

    final response = await dio.get(
      '/avaliacoes/minhas',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final items = response.data as List;
    return items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getContentReviews(
    int contentId,
    String type,
  ) async {
    if (contentId <= 0 || (type != 'MOVIE' && type != 'TV')) {
      throw ArgumentError('Conteúdo inválido');
    }

    final response = await dio.get(
      '/avaliacoes/filme/$contentId',
      queryParameters: {'tipoConteudo': type},
      options: Options(
        headers: {'Authorization': 'Bearer ${ApiService.token}'},
      ),
    );

    final items = response.data as List;
    return items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> getContentReviewSummary(
    int contentId,
    String type,
  ) async {
    if (contentId <= 0 || (type != 'MOVIE' && type != 'TV')) {
      throw ArgumentError('Conteúdo inválido');
    }

    final response = await dio.get(
      '/avaliacoes/conteudo/$contentId/resumo',
      queryParameters: {'tipoConteudo': type},
      options: Options(
        headers: {'Authorization': 'Bearer ${ApiService.token}'},
      ),
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> loadMyReviews() async {
    final items = await getMyReviews();

    final loadedReviews = await Future.wait(
      items.map((item) async {
        final contentId = (item['filmeSerieId'] as num).toInt();

        final type = item['tipoConteudo'] as String;
        final content = await getContent(contentId, type);

        return Review(
          id: (item['id'] as num).toInt(),
          content: content,
          rating: (item['nota'] as num).toDouble(),
          comment: item['comentario'] as String? ?? '',
          date: DateTime.parse(item['dataCriacao'] as String),
        );
      }),
    );
    ApiService.reviews = loadedReviews;
  }

  Future<void> loadMyReviewFor(Map<String, String> content) async {
    final contentId = int.parse(content['id']!);
    final type = content['type']!;
    final items = await getMyReviews();

    Review? found;

    for (final item in items) {
      final sameContent =
          (item['filmeSerieId'] as num).toInt() == contentId &&
          item['tipoConteudo'] == type;

      if (sameContent) {
        found = Review(
          id: (item['id'] as num).toInt(),
          content: content,
          rating: (item['nota'] as num).toDouble(),
          comment: item['comentario'] as String? ?? '',
          date: DateTime.parse(item['dataCriacao'] as String),
        );
        break;
      }
    }
    final updated = List<Review>.from(ApiService.reviews)
      ..removeWhere(
        (review) =>
            review.content['id'] == content['id'] &&
            review.content['type'] == type,
      );

    if (found != null) {
      updated.add(found);
    }
    ApiService.reviews = updated;
  }

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
    double rating,
    String comment,
  ) async {
    if (!rating.isFinite || rating < 0 || rating > 10) {
      throw ArgumentError('A nota deve ser de 0 a 10.');
    }
    final contentId = int.tryParse(content['id'] ?? '');
    final contentType = content['type'];
    if (contentId == null || contentId <= 0) {
      throw ArgumentError('ID do conteúdo inválido.');
    }
    if (contentType != 'MOVIE' && contentType != 'TV') {
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
        'tipoConteudo': contentType,
        'nota': rating,
        'comentario': comment.trim(),
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = Map<String, dynamic>.from(response.data as Map);

    final savedReview = Review(
      id: data['id'] as int,
      content: content,
      rating: (data['nota'] as num).toDouble(),
      comment: data['comentario'] as String? ?? '',
      date: DateTime.parse(data['dataCriacao'] as String),
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
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    ApiService.reviews = ApiService.reviews
        .where((item) => item.id != id)
        .toList();
  }
}
