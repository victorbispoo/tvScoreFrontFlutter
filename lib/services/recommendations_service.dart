part of 'api_services.dart';

class _RecommendationEntry {
  late final Future<Recommendations> future;
  DateTime? expiresAt;
}

extension RecommendationsService on ApiService {
  Future<Recommendations> getMovieRecommendations({bool refresh = false}) =>
      _getRecommendations('filmes', 'MOVIE', refresh);

  Future<Recommendations> getSeriesRecommendations({bool refresh = false}) =>
      _getRecommendations('series', 'TV', refresh);

  Future<Recommendations> _getRecommendations(
    String resource,
    String type,
    bool refresh,
  ) {
    if (ApiService.token?.isNotEmpty != true) {
      return Future.error(
        const RecommendationException(RecommendationFailure.invalidSession),
      );
    }
    final cache = ApiService._recommendations;
    final cached = cache[resource];
    if (cached != null) {
      final expiresAt = cached.expiresAt;
      if (expiresAt == null ||
          (!refresh && _recommendationClock().isBefore(expiresAt))) {
        return cached.future;
      }
    }

    final entry = cache[resource] = _RecommendationEntry();
    final session = ApiService._sessionVersion;
    entry.future = _fetchRecommendations(resource, type, session).then(
      (result) {
        if (!identical(cache[resource], entry)) {
          throw const RecommendationException(
            RecommendationFailure.invalidated,
          );
        }
        entry.expiresAt = _recommendationClock().add(
          const Duration(minutes: 15),
        );
        return result;
      },
      onError: (Object error, StackTrace stack) {
        if (identical(cache[resource], entry)) cache.remove(resource);
        Error.throwWithStackTrace(error, stack);
      },
    );
    return entry.future;
  }

  Future<Recommendations> _fetchRecommendations(
    String resource,
    String type,
    int session,
  ) async {
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
      if (session != ApiService._sessionVersion) {
        throw const RecommendationException(
          RecommendationFailure.invalidSession,
        );
      }
      final status = error.response?.statusCode;
      if (status == 401) {
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
      preferences: switch (data['preferencias']) {
        null => null,
        final Map values => Map<String, num>.unmodifiable(values),
        _ => throw const FormatException('Preferências inválidas.'),
      },
      total: data['total'] as int?,
      partial: data['parcial'] as bool?,
      warnings: switch (data['avisos']) {
        null => null,
        final List values => List<String>.unmodifiable(values),
        _ => throw const FormatException('Avisos inválidos.'),
      },
      items: List.unmodifiable([
        for (final item in data['recomendacoes'] as List)
          _parseRecommendation(item as Map<String, dynamic>, type),
      ]),
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
    if (item['ano'] case final int year) content['year'] = year.toString();
    if (absolutePoster) content['poster_path'] = poster;
    return Recommendation(
      content: Map.unmodifiable(content),
      rankingScore: item['score_recomendacao'] as num?,
      reason: item['motivo_recomendacao'] as String?,
      synopsisSimilarity: item['similaridade_sinopse'] as num?,
    );
  }
}
