part of 'api_services.dart';

extension FavoritesService on ApiService {
  Future<List<Map<String, dynamic>>> getSavedMovies() async {
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

  bool isSaved(Map<String, String> movie) {
    return ApiService.savedMovies.any(
      (saved) => saved['title'] == movie['title'],
    );
  }

  Future<void> toggleSaved(Map<String, String> movie) async {
    final movies = List<Map<String, String>>.from(ApiService.savedMovies);
    if (isSaved(movie)) {
      movies.removeWhere((saved) => saved['title'] == movie['title']);
    } else {
      movies.add(movie);
    }
    await _saveLibrary(movies, ApiService.reviews, ApiService.userName);
  }
}
