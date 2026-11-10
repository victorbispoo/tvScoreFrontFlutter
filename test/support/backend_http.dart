import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tv_score_front_flutter/data/mock_contents.dart';
import 'package:tv_score_front_flutter/models/content_metadata.dart';

// Backend em memória exclusivo dos testes: nenhuma chamada de rede real.
class BackendHttp extends HttpOverrides {
  final requests = <String>[];
  final reviews = <Map<String, dynamic>>[];
  final communityReviews = <Map<String, dynamic>>[];
  final favorites = <Map<String, dynamic>>[];
  final catalog = [
    for (var index = 0; index < mockContents.length; index++)
      {...mockContents[index], 'id': '${1000 + index}'},
  ];

  Map<String, dynamic> details(Map<String, String> content) => {
    'id': int.parse(content['id']!),
    'title': content['title'],
    'release_date': '${content['year']}-01-01',
    'overview': content['overview'] ?? '',
    'poster_path': '',
    'backdrop_path': '',
    'vote_average': double.parse(content['score'] ?? '8'),
    'genre_ids': content['genre_ids'] != null
        ? content['genre_ids']!.split(' | ').map(int.parse).toList()
        : [
            ContentGenres.names.entries
                .firstWhere(
                  (entry) => entry.value == content['genre'],
                  orElse: () => const MapEntry(18, 'Drama'),
                )
                .key,
          ],
    'tipoConteudo': content['type'],
  };

  Object? respond(String method, Uri uri, String body) {
    final path = uri.path.replaceFirst('/api', '');
    requests.add('$method $path');
    if (path == '/avaliacoes/minhas') return reviews;
    if (path == '/avaliacoes' && method == 'POST') {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final existing = reviews.where(
        (item) =>
            item['filmeSerieId'] == data['filmeSerieId'] &&
            item['tipoConteudo'] == data['tipoConteudo'],
      );
      final id = existing.isEmpty ? reviews.length + 1 : existing.first['id'];
      reviews.removeWhere((item) => item['id'] == id);
      final saved = {
        ...data,
        'id': id,
        'nomeUsuario': 'Usuário teste',
        'dataCriacao': '2026-11-08T12:00:00',
      };
      reviews.add(saved);
      return saved;
    }
    if (path.startsWith('/avaliacoes/') && method == 'DELETE') {
      reviews.removeWhere(
        (item) => item['id'].toString() == path.split('/').last,
      );
      return null;
    }
    if (path.startsWith('/avaliacoes/filme/') ||
        path.startsWith('/avaliacoes/conteudo/')) {
      final id = int.parse(path.split('/')[3]);
      final items = [...reviews, ...communityReviews]
          .where(
            (item) =>
                item['filmeSerieId'] == id &&
                item['tipoConteudo'] == uri.queryParameters['tipoConteudo'],
          )
          .toList();
      if (!path.endsWith('/resumo')) return items;
      return {
        'totalAvaliacoes': items.length,
        'media': items.isEmpty
            ? null
            : items.fold<double>(
                    0,
                    (sum, item) => sum + (item['nota'] as num),
                  ) /
                  items.length,
      };
    }
    if (path == '/favoritos') {
      if (method == 'POST') {
        favorites.add(jsonDecode(body) as Map<String, dynamic>);
      }
      return method == 'GET' ? favorites : null;
    }
    if (path.startsWith('/favoritos/') && method == 'DELETE') {
      favorites.removeWhere(
        (item) =>
            item['filmeSerieId'].toString() == path.split('/').last &&
            item['tipoConteudo'] == uri.queryParameters['tipoConteudo'],
      );
      return null;
    }
    if (path == '/filmes/pesquisar') {
      final term = (uri.queryParameters['q'] ?? '').toLowerCase();
      return {
        'results': catalog
            .where((item) => item['title']!.toLowerCase().contains(term))
            .map(details)
            .toList(),
        'page': 1,
        'total_pages': 1,
        'total_results': catalog
            .where((item) => item['title']!.toLowerCase().contains(term))
            .length,
      };
    }
    if (path.endsWith('/em-alta')) {
      final type = path.startsWith('/filmes') ? 'MOVIE' : 'TV';
      return {
        'results': catalog
            .where((item) => item['type'] == type)
            .map(details)
            .toList(),
      };
    }
    if (path.startsWith('/filmes/') || path.startsWith('/series/')) {
      final type = path.startsWith('/filmes') ? 'MOVIE' : 'TV';
      final content = catalog.firstWhere(
        (item) => item['id'] == path.split('/').last && item['type'] == type,
        orElse: () => {
          'id': path.split('/').last,
          'type': type,
          'title': 'Título de teste',
          'year': '2024',
          'score': '8.0',
          'genre': 'Drama',
        },
      );
      return details(content);
    }
    throw StateError('Rota sem fixture: $method $uri');
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) => _Client(this);
}

class _Client implements HttpClient {
  _Client(this.backend);
  final BackendHttp backend;
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _Request(backend, method, url);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Headers implements HttpHeaders {
  @override
  void forEach(void Function(String, List<String>) action) =>
      action('content-type', ['application/json']);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Request implements HttpClientRequest {
  _Request(this.backend, this.method, this.uri);
  final BackendHttp backend;
  @override
  final String method;
  @override
  final Uri uri;
  final _bytes = <int>[];
  @override
  final HttpHeaders headers = _Headers();
  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      _bytes.addAll(chunk);
    }
  }

  @override
  Future<HttpClientResponse> close() async =>
      _Response(backend.respond(method, uri, utf8.decode(_bytes)));
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(Object? data) : bytes = utf8.encode(jsonEncode(data));
  final List<int> bytes;
  @override
  int get statusCode => 200;
  @override
  int get contentLength => bytes.length;
  @override
  bool get isRedirect => false;
  @override
  List<RedirectInfo> get redirects => [];
  @override
  String get reasonPhrase => 'OK';
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  final HttpHeaders headers = _Headers();
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
