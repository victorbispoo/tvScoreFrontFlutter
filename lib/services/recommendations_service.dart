part of 'api_services.dart';

extension RecommendationsService on ApiService {
  Future<Recommendations> getMovieRecommendations() =>
      _getRecommendations('filmes', 'MOVIE');

  Future<Recommendations> getSeriesRecommendations() =>
      _getRecommendations('series', 'TV');

  Future<Recommendations> _getRecommendations(
    String resource,
    String type,
  ) async {
    final token = ApiService.token;
    if (token == null || token.isEmpty) {
      throw const RecommendationException(RecommendationFailure.invalidSession);
    }
    final session = ApiService._sessionVersion;

    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/recomendacoes/$resource',
        options: _authorizationOptions,
      );
      ApiService._checkSession(session);
      return _parseRecommendations(response.data, type);
    } on StateError {
      throw const RecommendationException(RecommendationFailure.invalidSession);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 &&
          session == ApiService._sessionVersion &&
          token == ApiService.token) {
        await _invalidateSession();
      }
      throw RecommendationException(switch (status) {
        401 => RecommendationFailure.invalidSession,
        403 => RecommendationFailure.accessDenied,
        502 => RecommendationFailure.invalidResponse,
        503 => RecommendationFailure.unavailable,
        504 => RecommendationFailure.timeout,
        _ => switch (error.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout => RecommendationFailure.timeout,
          _ when error.error is FormatException || error.error is TypeError =>
            RecommendationFailure.invalidResponse,
          _ => RecommendationFailure.requestFailed,
        },
      }, statusCode: status);
    } on TypeError {
      throw const RecommendationException(
        RecommendationFailure.invalidResponse,
      );
    } on FormatException {
      throw const RecommendationException(
        RecommendationFailure.invalidResponse,
      );
    }
  }

  Recommendations _parseRecommendations(
    Map<String, dynamic>? data,
    String type,
  ) {
    if (data == null || data['recomendacoes'] is! List) {
      throw const FormatException('Lista de recomendações ausente.');
    }
    return Recommendations(
      preferences: (data['preferencias'] as Map?)?.map(
        (key, value) => MapEntry(key as String, value as num),
      ),
      total: data['total'] as int?,
      partial: data['parcial'] as bool?,
      warnings: (data['avisos'] as List?)
          ?.map((value) => value as String)
          .toList(),
      items: [
        for (final item in data['recomendacoes'] as List)
          _parseRecommendation(item as Map<String, dynamic>, type),
      ],
    );
  }

  Recommendation _parseRecommendation(Map<String, dynamic> item, String type) {
    final id = item['id'];
    final suppliedType = (item['tipoConteudo'] as String?)
        ?.trim()
        .toUpperCase();
    if (id is! int ||
        id <= 0 ||
        (suppliedType != null && suppliedType != type)) {
      throw const FormatException('Identidade de recomendação inválida.');
    }
    final genres = item['generos'] as List?;
    final poster = item['poster'] as String? ?? '';
    final absolutePoster = Uri.tryParse(poster)?.hasAuthority ?? false;
    final content = _mapContent({
      'id': id,
      'title': item['titulo'],
      'overview': item['sinopse'],
      'vote_average': item['nota'],
      'genre_ids': genres,
      'genres': genres,
      'poster_path': absolutePoster ? null : poster,
    }, type);
    if (absolutePoster) content['poster_path'] = poster;
    return Recommendation(
      content: Map.unmodifiable(content),
      rankingScore: item['score_recomendacao'] as num?,
      reason: item['motivo_recomendacao'] as String?,
      synopsisSimilarity: item['similaridade_sinopse'] as num?,
    );
  }
}
