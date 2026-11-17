part of 'api_services.dart';

extension PreferencesService on ApiService {
  Future<List<Map<String, dynamic>>> getAvailableGenres() async {
    final response = await dio.get('/conteudos/generos');

    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> savePreferredGenres(List<String> codes) async {
    if (ApiService.token == null || ApiService.token!.isEmpty) {
      throw StateError('Entre na sua conta para salvar preferências.');
    }
    if (codes.length > 5) {
      throw ArgumentError('Selecione no máximo cinco gêneros.');
    }

    final session = ApiService._sessionVersion;
    await dio.put(
      '/usuarios/eu/generos',
      data: {'generos': codes},
      options: _authorizationOptions,
    );
    ApiService._checkSession(session);
  }

  Future<List<Map<String, String>>> getPreferredContents() async {
    final response = await dio.get(
      '/usuarios/eu/conteudos-preferidos',
      options: _authorizationOptions,
    );
    return (response.data['conteudos'] as List).map((item) {
      final data = Map<String, dynamic>.from(item as Map);
      final reference = requireContentReference(
        (data['id'] as num).toInt(),
        data['tipoConteudo'] as String,
      );
      return _mapContent({
        'id': reference.id,
        'title': data['titulo'],
        'overview': data['sinopse'],
        'release_date': data['dataLancamento'],
        'vote_average': data['notaTmdb'],
        'poster_path': data['posterPath'],
      }, reference.type);
    }).toList();
  }

  Future<({List<Map<String, String>> contents, int page, int totalPages})>
  getPreferredContentOptions({int page = 1}) async {
    if (page < 1 || page > ApiService.maxSearchPage) {
      throw ArgumentError.value(page, 'page');
    }
    final response = await dio.get(
      '/usuarios/eu/conteudos-preferidos/opcoes',
      queryParameters: {'pagina': page},
      options: _authorizationOptions,
    );
    final data = response.data as Map<String, dynamic>;
    return (
      contents: (data['results'] as List).map((item) {
        final content = Map<String, dynamic>.from(item as Map);
        return _mapContent(content, content['tipoConteudo'] as String);
      }).toList(),
      page: (data['page'] as num).toInt(),
      totalPages: (data['total_pages'] as num).toInt(),
    );
  }

  Future<void> savePreferredContents(List<Map<String, String>> contents) async {
    if (ApiService.token == null || ApiService.token!.isEmpty) {
      throw StateError('Entre na sua conta para salvar preferências.');
    }
    if (contents.length > 5) {
      throw ArgumentError('Selecione até cinco conteúdos.');
    }
    final references = contents.map((content) => content.apiReference).toSet();
    final session = ApiService._sessionVersion;
    await dio.put(
      '/usuarios/eu/conteudos-preferidos',
      data: {
        'conteudos': [
          for (final reference in references)
            {'id': reference.id, 'tipoConteudo': reference.type},
        ],
      },
      options: _authorizationOptions,
    );
    ApiService._checkSession(session);
  }

  Future<List<Map<String, dynamic>>> getPreferredGenres() async {
    if (ApiService.token == null || ApiService.token!.isEmpty) {
      throw StateError('Entre na sua conta para consultar preferências.');
    }

    final response = await dio.get(
      '/usuarios/eu/generos',
      options: _authorizationOptions,
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    final genres = data['generos'] as List;

    return genres
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
