class SearchFilters {
  const SearchFilters({
    this.type,
    this.genres = const {},
    this.year,
    this.minimumRating,
  });

  final String? type;
  final Set<String> genres;
  final int? year;
  final int? minimumRating;

  bool get isActive =>
      type != null ||
      genres.isNotEmpty ||
      year != null ||
      minimumRating != null;

  bool matches(Map<String, String> content) {
    if (type != null && content['type'] != type) return false;
    if (year != null && content['year'] != year.toString()) return false;
    if (minimumRating != null &&
        (double.tryParse(content['score'] ?? '') ?? -1) < minimumRating!) {
      return false;
    }
    if (genres.isNotEmpty) {
      final names = (content['genre'] ?? '')
          .split(' • ')
          .map((name) => name.trim().toLowerCase());
      if (!names.any(
        (name) => genres.any((genre) => genre.toLowerCase() == name),
      )) {
        return false;
      }
    }
    return true;
  }
}
