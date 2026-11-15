Object posterHeroTag(
  String origin,
  Map<String, String> content, {
  int occurrence = 0,
}) => ('poster', origin, content['type'], content['id'], occurrence);
