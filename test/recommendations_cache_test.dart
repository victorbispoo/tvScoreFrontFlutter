import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/models/recommendations.dart';
import 'package:tv_score_front_flutter/models/review.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const movie = {'id': '7', 'type': 'MOVIE'};
  late DateTime now;
  late ApiService api;
  late List<String> reads;
  late Future<int> Function(RequestOptions, int) recommend;
  late bool failWrite;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    ApiService.token = 'account-a';
    now = DateTime.utc(2026);
    reads = [];
    recommend = (_, count) async => count;
    failWrite = false;
    api = ApiService(recommendationClock: () => now);
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) async {
          final isRead = request.path.startsWith('/recomendacoes/');
          final id = isRead
              ? await recommend(request, (reads..add(request.path)).length)
              : 0;
          if ((isRead && id == 0) || (!isRead && failWrite)) {
            handler.reject(
              DioException.badResponse(
                statusCode: 503,
                requestOptions: request,
                response: Response(requestOptions: request, statusCode: 503),
              ),
            );
            return;
          }
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: 200,
              data: isRead
                  ? {
                      'recomendacoes': [
                        {'id': id},
                      ],
                    }
                  : switch (request.path) {
                      '/auth/login' => {
                        'token': 'account-b',
                        'email': 'b@example.com',
                        'nome': 'B',
                        'fotoUrl': null,
                      },
                      '/avaliacoes' => {
                        'id': 1,
                        'nota': request.data['nota'],
                        'dataCriacao': '2026-01-01',
                      },
                      _ => null,
                    },
            ),
          );
        },
      ),
    );
  });
  tearDown(() => api.logout());

  int id(Recommendations result) => result.items.single.identity.id;

  Matcher failsWith(RecommendationFailure failure) => throwsA(
    isA<RecommendationException>().having(
      (error) => error.failure,
      'failure',
      failure,
    ),
  );

  test('compartilha cache na sessão e expira em 15 minutos', () async {
    final first = await api.getMovieRecommendations();
    now = now.add(const Duration(minutes: 14, seconds: 59));
    final other = ApiService(recommendationClock: () => now);
    expect(await other.getMovieRecommendations(), same(first));
    now = now.add(const Duration(seconds: 1));
    expect(id(await api.getMovieRecommendations()), 2);
    expect(reads, hasLength(2));
  });

  test('deduplica leituras simultâneas e refresh manual', () async {
    final first = api.getMovieRecommendations();
    expect(api.getMovieRecommendations(), same(first));
    expect(api.getMovieRecommendations(refresh: true), same(first));
    expect(id(await first), 1);
    final refresh = api.getMovieRecommendations(refresh: true);
    expect(api.getMovieRecommendations(refresh: true), same(refresh));
    expect(api.getMovieRecommendations(), same(refresh));
    expect(id(await refresh), 2);
  });

  final writes = <String, Future<void> Function()>{
    'criar avaliação': () => api.saveReview(movie, 8, ''),
    'editar avaliação': () => api.saveReview(movie, 9, ''),
    'excluir avaliação': () => api.deleteReview(
      Review(id: 1, content: movie, rating: 8, comment: '', date: now),
    ),
    'adicionar favorito': () => api.addFavourite(movie),
    'remover favorito': () => api.removeFavourite(movie),
    'salvar gêneros': () => api.savePreferredGenres(['DRAMA']),
    'salvar conteúdos': () => api.savePreferredContents([movie]),
  };
  for (final action in writes.entries) {
    test('${action.key} só invalida após sucesso', () async {
      if (action.key == 'editar avaliação') await api.saveReview(movie, 8, '');
      final movies = await api.getMovieRecommendations();
      final series = await api.getSeriesRecommendations();
      failWrite = true;
      await expectLater(action.value(), throwsA(isA<DioException>()));
      expect(await api.getMovieRecommendations(), same(movies));
      expect(await api.getSeriesRecommendations(), same(series));
      failWrite = false;
      await action.value();
      expect(reads, hasLength(2));
      expect(id(await api.getMovieRecommendations()), 3);
      expect(id(await api.getSeriesRecommendations()), 4);
    });
  }

  test('logout e login descartam cache e resposta da conta anterior', () async {
    await api.getSeriesRecommendations();
    final started = Completer<void>();
    final release = Completer<int>();
    recommend = (_, count) {
      if (count != 2) return Future.value(count);
      started.complete();
      return release.future;
    };
    final pending = expectLater(
      api.getMovieRecommendations(),
      failsWith(RecommendationFailure.invalidSession),
    );
    await started.future;
    await api.logout();
    await expectLater(
      api.getSeriesRecommendations(),
      failsWith(RecommendationFailure.invalidSession),
    );
    await api.loginApi('b@example.com', 'password');
    expect(id(await api.getSeriesRecommendations()), 3);
    final current = await api.getMovieRecommendations();
    release.complete(2);
    await pending;
    expect(await api.getMovieRecommendations(), same(current));
  });

  test(
    'resposta anterior à invalidação não substitui o resultado novo',
    () async {
      final started = Completer<void>();
      final release = Completer<int>();
      recommend = (_, count) {
        if (count != 1) return Future.value(count);
        started.complete();
        return release.future;
      };
      final pending = expectLater(
        api.getMovieRecommendations(),
        failsWith(RecommendationFailure.invalidated),
      );
      await started.future;
      await api.savePreferredGenres(['DRAMA']);
      final current = await api.getMovieRecommendations();
      release.complete(1);
      await pending;
      expect(id(current), 2);
      expect(await api.getMovieRecommendations(), same(current));
      expect(reads, hasLength(2));
    },
  );

  test('falha de filmes permite retry sem afetar séries', () async {
    recommend = (_, count) async => count == 1 ? 0 : count;
    await expectLater(
      api.getMovieRecommendations(),
      failsWith(RecommendationFailure.unavailable),
    );
    final series = await api.getSeriesRecommendations();
    expect(id(await api.getMovieRecommendations()), 3);
    expect(await api.getSeriesRecommendations(), same(series));
  });
}
