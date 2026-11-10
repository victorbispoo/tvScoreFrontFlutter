part of 'api_services.dart';

extension FavoritesService on ApiService {
  Future<List<Map<String, dynamic>>> getFavorites() async {
    final session = ApiService._sessionVersion;
    final response = await dio.get(
      '/favoritos',
      options: _authorizationOptions,
    );
    ApiService._checkSession(session);
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> addFavourite(Map<String, String> content) async {
    final reference = content.apiReference;
    await dio.post(
      '/favoritos',
      data: {'filmeSerieId': reference.id, 'tipoConteudo': reference.type},
      options: _authorizationOptions,
    );
  }

  Future<void> removeFavourite(Map<String, String> content) async {
    final reference = content.apiReference;
    await dio.delete(
      '/favoritos/${reference.id}',
      queryParameters: {'tipoConteudo': reference.type},
      options: _authorizationOptions,
    );
  }

  Future<void> loadFavorites() async {
    final session = ApiService._sessionVersion;
    final favorites = await getFavorites();
    final contents = await Future.wait(
      favorites.map(
        (favorite) => getContent(
          (favorite['filmeSerieId'] as num).toInt(),
          favorite['tipoConteudo'] as String,
        ),
      ),
    );
    ApiService._checkSession(session);
    ApiService.savedContents = contents;
  }

  bool isSaved(Map<String, String> content) => ApiService.savedContents.any(
    (saved) => saved.contentKey == content.contentKey,
  );

  Future<void> toggleSaved(Map<String, String> content) async {
    final session = ApiService._sessionVersion;
    final contents = List<Map<String, String>>.from(ApiService.savedContents);
    if (isSaved(content)) {
      await removeFavourite(content);
      contents.removeWhere((saved) => saved.contentKey == content.contentKey);
    } else {
      await addFavourite(content);
      contents.add(content);
    }
    ApiService._checkSession(session);
    ApiService.savedContents = contents;
  }
}
