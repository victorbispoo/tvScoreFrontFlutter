part of 'api_services.dart';

extension FavoritesService on ApiService {
  Future<List<Map<String, dynamic>>> getSavedContents() async {
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

    if (type != 'movie' && type != 'tv') {
      throw ArgumentError('Tipo de conteúdo inválido.');
    }

    final tipoConteudo = type == 'movie' ? 'MOVIE' : 'TV';

    try {
      await dio.post(
        '/favoritos',
        data: {'filmeSerieId': id, 'tipoConteudo': tipoConteudo},
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
    if (type != 'movie' && type != 'tv') {
      throw ArgumentError('Tipo de conteúdo inválido.');
    }

    final tipoConteudo = type == 'movie' ? 'MOVIE' : 'TV';

    await dio.delete(
      '/favoritos/$id',
      queryParameters: {'tipoConteudo': tipoConteudo},
      options: Options(
        headers: {'Authorization': 'Bearer ${ApiService.token}'},
      ),
    );
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
    await _saveLibrary(contents, ApiService.reviews, ApiService.userName);
  }
}
