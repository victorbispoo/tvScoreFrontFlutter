import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/models/recommendations.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ApiService api;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ApiService.token = 'test-token';
    api = ApiService();
  });
  tearDown(() => ApiService.token = null);

  void respond(String resource, Object data, {int status = 200}) {
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          expect(request.method, 'GET');
          expect(request.uri.path, '/api/recomendacoes/$resource');
          expect(request.uri.host, Uri.parse(api.dio.options.baseUrl).host);
          expect(request.headers['Authorization'], 'Bearer test-token');
          final response = Response(
            requestOptions: request,
            data: data,
            statusCode: status,
          );
          if (status == 200) {
            handler.resolve(response);
          } else {
            handler.reject(
              DioException.badResponse(
                statusCode: status,
                requestOptions: request,
                response: response,
              ),
            );
          }
        },
      ),
    );
  }

  test(
    'normalizes movie cards without reordering or replacing the rating',
    () async {
      respond('filmes', {
        'preferencias': {'18': 0.5},
        'total': 2,
        'parcial': true,
        'avisos': ['Catálogo parcial'],
        'recomendacoes': [
          {
            'id': 7,
            'titulo': 'Filme',
            'sinopse': 'Sinopse',
            'nota': 8.2,
            'generos': [18],
            'poster': '/filme.jpg',
            'score_recomendacao': 2.5,
            'motivo_recomendacao': 'Drama',
            'similaridade_sinopse': 0.4,
          },
          {'id': 2, 'score_recomendacao': 9},
        ],
      });

      final result = await api.getMovieRecommendations();
      expect(result.preferences, {'18': 0.5});
      expect(result.total, 2);
      expect(result.partial, isTrue);
      expect(result.warnings, ['Catálogo parcial']);
      expect(result.items.map((item) => item.identity.id), [7, 2]);
      final first = result.items.first;
      expect(first.identity, (id: 7, type: 'MOVIE'));
      expect(first.content, containsPair('score', '8.2'));
      expect(first.content, containsPair('title', 'Filme'));
      expect(first.content, containsPair('overview', 'Sinopse'));
      expect(first.content, containsPair('genre_ids', '18'));
      expect(
        first.content['poster_path'],
        'https://image.tmdb.org/t/p/w500/filme.jpg',
      );
      expect(first.rankingScore, 2.5);
      expect(first.reason, 'Drama');
      expect(first.synopsisSimilarity, 0.4);
      expect(result.items.last.reason, isNull);
      expect(result.items.last.content['poster_path'], isEmpty);
    },
  );

  test(
    'normalizes series and distinguishes a movie with the same id',
    () async {
      const poster = 'https://image.tmdb.org/t/p/w500/serie.jpg';
      respond('series', {
        'recomendacoes': [
          {'id': 7, 'titulo': 'Série', 'poster': poster, 'tipoConteudo': 'tv'},
        ],
      });
      final result = await api.getSeriesRecommendations();
      final series = result.items.single;
      expect(series.identity, (id: 7, type: 'TV'));
      expect(series.identity, isNot((id: 7, type: 'MOVIE')));
      expect(series.content['poster_path'], poster);
      expect(series.rankingScore, isNull);
      expect(result.partial, isNull);
      expect(result.warnings, isNull);
    },
  );

  test('accepts an empty recommendation list', () async {
    respond('filmes', {'total': 0, 'recomendacoes': []});
    expect((await api.getMovieRecommendations()).items, isEmpty);
  });

  test('rejects a recommendation without an identity', () async {
    respond('series', {
      'recomendacoes': [{}],
    });
    await expectLater(
      api.getSeriesRecommendations(),
      throwsA(
        isA<RecommendationException>().having(
          (error) => error.failure,
          'failure',
          RecommendationFailure.invalidResponse,
        ),
      ),
    );
  });

  for (final (status, failure) in const [
    (401, RecommendationFailure.invalidSession),
    (403, RecommendationFailure.accessDenied),
    (502, RecommendationFailure.invalidResponse),
    (503, RecommendationFailure.unavailable),
    (504, RecommendationFailure.timeout),
  ]) {
    test('maps HTTP $status to ${failure.name}', () async {
      respond('filmes', {}, status: status);
      await expectLater(
        api.getMovieRecommendations(),
        throwsA(
          isA<RecommendationException>()
              .having((error) => error.statusCode, 'statusCode', status)
              .having((error) => error.failure, 'failure', failure),
        ),
      );
      expect(ApiService.token, status == 401 ? isNull : 'test-token');
    });
  }
}
