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

    await dio.put(
      '/usuarios/eu/generos',
      data: {'generos': codes},
      options: _authorizationOptions,
    );
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
