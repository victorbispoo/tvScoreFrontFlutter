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
    final session = ApiService._sessionVersion;
    final reference = content.apiReference;
    await dio.post(
      '/favoritos',
      data: {'filmeSerieId': reference.id, 'tipoConteudo': reference.type},
      options: _authorizationOptions,
    );
    ApiService._invalidateRecommendations(session);
  }

  Future<void> removeFavourite(Map<String, String> content) async {
    final session = ApiService._sessionVersion;
    final reference = content.apiReference;
    await dio.delete(
      '/favoritos/${reference.id}',
      queryParameters: {'tipoConteudo': reference.type},
      options: _authorizationOptions,
    );
    ApiService._invalidateRecommendations(session);
  }

  Future<void> _queueFavorites(Future<void> Function() action) {
    final session = ApiService._sessionVersion;
    final previous = ApiService._favoritesOperation;
    final next = () async {
      if (previous != null) await previous;
      ApiService._checkSession(session);
      await action();
    }();
    // A failed operation must not block later retries in the same session.
    ApiService._favoritesOperation = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return next;
  }

  Future<void> ensureFavoritesLoaded() =>
      ApiService._favoritesLoaded ? Future.value() : loadFavorites();

  Future<void> loadFavorites() {
    final pending = ApiService._favoritesLoad;
    if (pending != null) return pending;
    final session = ApiService._sessionVersion;
    return ApiService._favoritesLoad = _queueFavorites(_readFavorites)
        .whenComplete(() {
          if (session == ApiService._sessionVersion) {
            ApiService._favoritesLoad = null;
          }
        });
  }

  Future<void> _readFavorites() async {
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
    ApiService._favoritesLoaded = true;
    ApiService.savedContents = contents;
  }

  bool isSaved(Map<String, String> content) => ApiService.savedContents.any(
    (saved) => saved.contentKey == content.contentKey,
  );

  Future<void> toggleSaved(Map<String, String> content) =>
      _changeSaved(content);

  Future<void> setSaved(Map<String, String> content, bool saved) =>
      _changeSaved(content, saved: saved);

  Future<void> _changeSaved(
    Map<String, String> content, {
    bool? saved,
  }) => _queueFavorites(() async {
    final session = ApiService._sessionVersion;
    try {
      if (!ApiService._favoritesLoaded) await _readFavorites();
      final contents = List<Map<String, String>>.from(ApiService.savedContents);
      final shouldSave = saved ?? !isSaved(content);
      if (shouldSave == isSaved(content)) return;
      if (!shouldSave) {
        await removeFavourite(content);
        contents.removeWhere((saved) => saved.contentKey == content.contentKey);
      } else {
        await addFavourite(content);
        contents.add(content);
      }
      ApiService._checkSession(session);
      ApiService.savedContents = contents;
    } catch (_) {
      if (session == ApiService._sessionVersion) {
        ApiService._favoritesLoaded = false;
      }
      rethrow;
    }
  });
}
