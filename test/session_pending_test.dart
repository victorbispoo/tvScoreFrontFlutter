import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/models/review.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final operation in [
    'favorites',
    'reviews',
    'personal',
    'save',
    'toggle',
    'delete',
  ]) {
    test('resposta pendente de $operation não altera outra sessão', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final api = ApiService();
      await api.logout();
      ApiService.token = 'same-token';
      final started = Completer<void>();
      final release = Completer<void>();
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            started.complete();
            await release.future;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: options.path == '/avaliacoes'
                    ? {
                        'id': 1,
                        'nota': 8.0,
                        'comentario': null,
                        'dataCriacao': '2026-11-08T12:00:00',
                      }
                    : [],
              ),
            );
          },
        ),
      );

      const content = {'id': '123', 'type': 'MOVIE'};
      final pending = switch (operation) {
        'favorites' => api.loadFavorites(),
        'reviews' => api.loadMyReviews(),
        'personal' => api.loadMyReviewFor(content),
        'save' => api.saveReview(content, 8, ''),
        'toggle' => api.toggleSaved(content),
        _ => api.deleteReview(
          Review(
            id: 1,
            content: content,
            rating: 8,
            comment: '',
            date: DateTime(2026),
          ),
        ),
      };
      final check = expectLater(pending, throwsStateError);
      await started.future;
      await api.logout();
      // Mesmo token após novo login também precisa invalidar a resposta antiga.
      ApiService.token = 'same-token';
      ApiService.savedContents = [
        const {'id': '999', 'type': 'TV'},
      ];
      release.complete();
      await check;
      expect(ApiService.savedContents.single['id'], '999');
      expect(ApiService.reviews, isEmpty);
      await api.logout();
    });
  }
}
