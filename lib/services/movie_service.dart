part of 'api_services.dart';

extension MovieService on ApiService {
  Future<List<Map<String, String>>> getHighlights() async {
    if (ApiService.useMockMovies) {
      return mockMovies
          .map((movie) => Map<String, String>.from(movie))
          .toList();
    }
    final response = await dio.get('/filmes/em-alta');

    final results = response.data['results'] as List;

    return results.map<Map<String, String>>((filme) {
      final data = filme['release_date'] as String? ?? '';
      final poster = filme['poster_path'] as String?;
      final ids = filme['genre_ids'] as List? ?? [];
      final generoPrincipal = ids.isEmpty
          ? 'não informado'
          : ApiService.generos[ids.first] ?? 'não informado';
      return {
        'id': filme['id'].toString(),
        'title': filme['title'] as String? ?? 'Sem título',
        'overview': filme['overview'] as String? ?? '',
        'year': data.length >= 4 ? data.substring(0, 4) : '',
        'score': (filme['vote_average'] as num?)?.toStringAsFixed(1) ?? '0.0',
        'poster_path': poster == null || poster.isEmpty
            ? ''
            : 'https://image.tmdb.org/t/p/w500$poster',
        'genre_ids': filme['genre_ids']?.join(' | ') ?? '',
        'genre': generoPrincipal,
        'type': filme['media_type'] as String? ?? 'movie',
      };
    }).toList();
  }

  // Pendente no arquivo original: Future<Map<String,String>> getMovie
}
