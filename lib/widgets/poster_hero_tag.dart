import '../models/content_metadata.dart';

Object posterHeroTag(
  String origin,
  Map<String, String> content, {
  int occurrence = 0,
}) => ('poster', origin, content['type'], content['id'], occurrence);

List<Object> carouselPosterHeroTags(
  String origin,
  List<Map<String, String>> contents,
) {
  final occurrences = <(String?, String?), int>{};
  return [
    for (final content in contents)
      posterHeroTag(
        origin,
        content,
        occurrence: occurrences.update(
          content.contentKey,
          (count) => count + 1,
          ifAbsent: () => 0,
        ),
      ),
  ];
}
