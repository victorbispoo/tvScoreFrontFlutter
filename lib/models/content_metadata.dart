({int id, String type}) requireContentReference(int? id, String? type) {
  if (id == null || id <= 0) {
    throw ArgumentError('O conteúdo precisa ter um ID válido.');
  }
  if (type != 'MOVIE' && type != 'TV') {
    throw ArgumentError('Tipo de conteúdo inválido. Deve ser MOVIE ou TV.');
  }
  return (id: id, type: type!);
}

extension ContentMetadata on Map<String, String> {
  (String?, String?) get contentKey => (this['id'], this['type']);

  ({int id, String type}) get apiReference =>
      requireContentReference(int.tryParse(this['id'] ?? ''), this['type']);

  String get primaryGenre {
    final name = (this['genre'] ?? '').split(' • ').first.trim();
    return name.isEmpty ? 'não informado' : name;
  }

  bool hasAnyGenre(Set<int> ids) => (this['genre_ids'] ?? '')
      .split('|')
      .map((value) => int.tryParse(value.trim()))
      .any(ids.contains);
}

abstract final class ContentGenres {
  static const names = <int, String>{
    28: 'Ação',
    12: 'Aventura',
    16: 'Animação',
    35: 'Comédia',
    80: 'Crime',
    99: 'Documentário',
    18: 'Drama',
    10751: 'Família',
    14: 'Fantasia',
    36: 'História',
    27: 'Terror',
    10402: 'Música',
    9648: 'Mistério',
    10749: 'Romance',
    878: 'Ficção Científica',
    10770: 'Filme para TV',
    53: 'Suspense',
    10752: 'Guerra',
    37: 'Faroeste',
    10759: 'Ação e Aventura',
    10762: 'Infantil',
    10763: 'Notícias',
    10764: 'Reality',
    10765: 'Ficção Científica e Fantasia',
    10766: 'Novela',
    10767: 'Talk Show',
    10768: 'Guerra e Política',
  };
  static final _idsByName = <String, int>{
    for (final entry in names.entries) entry.value.toLowerCase(): entry.key,
    'action & adventure': 10759,
    'sci-fi & fantasy': 10765,
    'kids': 10762,
    'news': 10763,
    'soap': 10766,
    'talk': 10767,
    'war & politics': 10768,
  };

  // O Java envia nomes na pesquisa/detalhes e IDs nas listagens.
  static ({String ids, String labels}) fromJson(Map<String, dynamic> data) {
    final ids = (data['genre_ids'] as List? ?? [])
        .whereType<num>()
        .map((id) => id.toInt())
        .toSet();
    final labels = <String>{};
    for (final name in (data['genres'] as List? ?? []).whereType<String>()) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      final id = _idsByName[trimmed.toLowerCase()];
      if (id != null) ids.add(id);
      labels.add(names[id] ?? trimmed);
    }
    for (final id in ids) {
      final name = names[id];
      if (name != null) labels.add(name);
    }
    return (
      ids: ids.join(' | '),
      labels: labels.isEmpty ? 'não informado' : labels.join(' • '),
    );
  }
}
