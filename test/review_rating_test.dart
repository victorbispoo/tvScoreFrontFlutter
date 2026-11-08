import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

void main() {
  for (final returnedRating in <num>[8, 8.0, 8.5]) {
    test('interpreta nota $returnedRating como double', () async {
      final api = ApiService();
      ApiService.token = 'test-token';
      ApiService.reviews = [];
      addTearDown(() {
        ApiService.token = null;
        ApiService.reviews = [];
      });
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/avaliacoes');
            expect(options.data['nota'], 8.0);
            expect(options.data['tipoConteudo'], 'MOVIE');
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 1,
                'nota': returnedRating,
                'comentario': '',
                'dataCriacao': '2026-11-07T12:00:00',
              },
            ));
          },
        ),
      );

      await api.saveReview({'id': '123', 'type': 'MOVIE'}, 8.0, '');

      expect(ApiService.reviews.single.rating, isA<double>());
      expect(ApiService.reviews.single.rating, returnedRating.toDouble());
    });
  }
}
