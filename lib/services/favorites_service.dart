part of 'api_services.dart';

extension FavoritesService on ApiService {
  Future<List<Map<String, dynamic>>> getFavorites() async {
    final response = await dio.get(
      '/favoritos',
      options: Options(
        headers: {'Authorization': 'Bearer ${ApiService.token}'},
      ),
    );
    final dados = response.data as List;

    return dados.map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  Future<void> addFavourite(Map<String, String> content) async {
    final id = int.tryParse(content['id'] ?? '');
    final type = content['type'];
  debugPrint(
  'Favoritando: id=${content['id']}, type=${content['type']}',
);
    if (id == null) {
      throw ArgumentError('O conteúdo precisa ter um ID válido.');
    }

    if (type != 'MOVIE' && type != 'TV') {
      throw ArgumentError('Tipo de conteúdo inválido.');
    }


    try {
      await dio.post(
        '/favoritos',
        data: {'filmeSerieId': id, 'tipoConteudo': type},
        options: Options(
          headers: {'Authorization': 'Bearer ${ApiService.token}'},
        ),
      );
    } on DioException catch (error) {
      debugPrint('Erro ao adicionar favorito');
      debugPrint('Tipo: ${error.type}');
      debugPrint('Status: ${error.response?.statusCode}');
      debugPrint('Resposta: ${error.response?.data}');
      rethrow;
    }
  }

  Future<void> removeFavourite(Map<String, String> content) async {
    final id = int.tryParse(content['id'] ?? '');
    final type = content['type'];

    if (id == null) {
      throw ArgumentError('O conteúdo precisa ter um ID válido.');
    }
    if (type != 'MOVIE' && type != 'TV') {
      throw ArgumentError('Tipo de conteúdo inválido.');
    }


    await dio.delete(
      '/favoritos/$id',
      queryParameters: {'tipoConteudo': type},
      options: Options(
        headers: {'Authorization': 'Bearer ${ApiService.token}'},
      ),
    );
  }

  Future<void> loadFavorites() async {
    final favorites = await getFavorites();

    final contents = await Future.wait(
      favorites.map((favorite) {
        final id = (favorite['filmeSerieId'] as num).toInt();

        final type = favorite['tipoConteudo'] as String;
        return getContent(id, type);
      })
    );
    ApiService.savedContents = contents;
  }

  bool isSaved(Map<String, String> content) {
    return ApiService.savedContents.any(
      (saved) =>
          saved['id'] == content['id'] && saved['type'] == content['type'],
    );
  }

  

  Future<void> toggleSaved(Map<String, String> content) async {
    final contents = List<Map<String, String>>.from(ApiService.savedContents);
    if (isSaved(content)) {
      await removeFavourite(content);
      contents.removeWhere(
        (saved) =>
            saved['id'] == content['id'] && saved['type'] == content['type'],
      );
    } else {
      await addFavourite(content);
      contents.add(content);
    }
    ApiService.savedContents = contents;
  }
}
