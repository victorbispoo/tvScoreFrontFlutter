import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/models/content_metadata.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

ApiService apiReturning(Map<String, dynamic> data) {
  final api = ApiService();
  api.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response(requestOptions: options, statusCode: 200, data: data),
      ),
    ),
  );
  return api;
}

void main() {
  for (final search in [false, true]) {
    test(
      '${search ? 'pesquisa' : 'detalhes'} lê os nomes enviados pelo Java',
      () async {
        final data = <String, dynamic>{
          'id': 37854,
          'title': 'One Piece',
          'tipoConteudo': 'TV',
          'genres': ['Action & Adventure', 'Comédia', 'Animação'],
        };
        final api = apiReturning(
          search
              ? {
                  'results': [data],
                  'page': 1,
                  'total_pages': 1,
                }
              : data,
        );
        final content = search
            ? (await api.searchContents('one piece')).contents.single
            : await api.getContent(37854, 'TV');

        expect(content['genre'], 'Ação e Aventura • Comédia • Animação');
        expect(content.hasAnyGenre({10759}), isTrue);
        expect(content.hasAnyGenre({16}), isTrue);
        expect(content.hasAnyGenre({18}), isFalse);
      },
    );
  }

  test(
    'listagens preservam todos os IDs e reconhecem gêneros de séries',
    () async {
      final api = apiReturning({
        'results': [
          {
            'id': 1,
            'tipoConteudo': 'TV',
            'genre_ids': [16, 10759, 10765, 18],
          },
        ],
      });
      final content = (await api.getHighlights()).first;
      expect(
        content['genre'],
        'Animação • Ação e Aventura • Ficção Científica e Fantasia • Drama',
      );
      expect(content.hasAnyGenre({28, 12, 10759}), isTrue);
      expect(content.hasAnyGenre({878, 10765}), isTrue);
      expect(content.hasAnyGenre({18}), isTrue);
    },
  );

  test(
    'converte Sci-Fi & Fantasy recebido na pesquisa em gênero de série',
    () async {
      final api = apiReturning({
        'id': 111110,
        'genres': ['Action & Adventure', 'Sci-Fi & Fantasy'],
      });
      final content = await api.getContent(111110, 'TV');
      expect(
        content['genre'],
        'Ação e Aventura • Ficção Científica e Fantasia',
      );
      expect(content.hasAnyGenre({878, 10765}), isTrue);
    },
  );

  test(
    'IDs desconhecidos não escondem os gêneros seguintes e aventura entra no filtro',
    () async {
      final api = apiReturning({
        'id': 1,
        'genre_ids': [999999, 16, 12],
      });
      final content = await api.getContent(1, 'MOVIE');
      expect(content['genre'], 'Animação • Aventura');
      expect(content['genre_ids'], '999999 | 16 | 12');
      expect(content.hasAnyGenre({28, 12, 10759}), isTrue);
    },
  );

  test('preserva nome novo e elimina nomes repetidos ou vazios', () async {
    final api = apiReturning({
      'id': 1,
      'genres': [' ', 'Drama', 'Drama', 'Gênero novo'],
      'genre_ids': [18],
    });
    final content = await api.getContent(1, 'MOVIE');
    expect(content['genre'], 'Drama • Gênero novo');
    expect(content['genre_ids'], '18');
  });

  for (final data in <Map<String, dynamic>>[
    {},
    {'genres': null, 'genre_ids': null},
    {'genres': [], 'genre_ids': []},
  ]) {
    test('ausência de gêneros mantém o fallback: $data', () async {
      final content = await apiReturning(data).getContent(1, 'MOVIE');
      expect(content['genre'], 'não informado');
      expect(content.hasAnyGenre({18}), isFalse);
    });
  }
}
