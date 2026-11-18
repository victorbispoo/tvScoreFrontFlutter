import 'content_metadata.dart';

class Recommendations {
  const Recommendations({
    required this.preferences,
    required this.total,
    required this.items,
    required this.partial,
    required this.warnings,
  });

  final Map<String, num>? preferences;
  final int? total;
  final List<Recommendation> items;
  final bool? partial;
  final List<String>? warnings;
}

class Recommendation {
  const Recommendation({
    required this.content,
    this.rankingScore,
    this.reason,
    this.synopsisSimilarity,
  });

  final Map<String, String> content;
  final num? rankingScore;
  final String? reason;
  final num? synopsisSimilarity;

  ({int id, String type}) get identity => content.apiReference;
}

enum RecommendationFailure {
  invalidSession,
  accessDenied,
  invalidResponse,
  unavailable,
  timeout,
  requestFailed,
}

class RecommendationException implements Exception {
  const RecommendationException(this.failure, {this.statusCode});

  final RecommendationFailure failure;
  final int? statusCode;
}
