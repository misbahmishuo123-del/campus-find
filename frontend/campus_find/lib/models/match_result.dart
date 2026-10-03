import 'item.dart';

class MatchScore {
  final int category;
  final int location;
  final int dateTime;
  final int description;
  final int colorBrand;
  final int total;
  final String label;

  MatchScore({
    required this.category,
    required this.location,
    required this.dateTime,
    required this.description,
    required this.colorBrand,
    required this.total,
    required this.label,
  });

  factory MatchScore.fromJson(Map<String, dynamic> json) {
    return MatchScore(
      category: (json['category'] ?? 0) as int,
      location: (json['location'] ?? 0) as int,
      dateTime: (json['dateTime'] ?? 0) as int,
      description: (json['description'] ?? 0) as int,
      colorBrand: (json['colorBrand'] ?? 0) as int,
      total: (json['total'] ?? 0) as int,
      label: json['label']?.toString() ?? '',
    );
  }
}

class MatchResult {
  final Item item;
  final MatchScore score;

  MatchResult({required this.item, required this.score});

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      item: Item.fromJson(json['item'] as Map<String, dynamic>),
      score: MatchScore.fromJson(json['score'] as Map<String, dynamic>),
    );
  }
}
