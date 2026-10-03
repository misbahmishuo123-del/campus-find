import 'user.dart';

class Item {
  final String id;
  final String type; // lost | found
  final String title;
  final String category;
  final String description;
  final String? color;
  final String? brand;
  final String location;
  final DateTime date;
  final String? time;
  final String? imageUrl;
  final AppUser? createdBy;
  final String? createdById;
  final String status;
  final String claimStatus;
  final String? verificationQuestion;
  final DateTime? returnedAt;
  final DateTime createdAt;

  Item({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.description,
    required this.location,
    required this.date,
    required this.status,
    required this.claimStatus,
    required this.createdAt,
    this.color,
    this.brand,
    this.time,
    this.imageUrl,
    this.createdBy,
    this.createdById,
    this.verificationQuestion,
    this.returnedAt,
  });

  bool get isLost => type == 'lost';

  factory Item.fromJson(Map<String, dynamic> json) {
    final createdByRaw = json['createdBy'];
    AppUser? owner;
    String? ownerId;
    if (createdByRaw is Map<String, dynamic>) {
      owner = AppUser.fromJson(createdByRaw);
      ownerId = owner.id;
    } else if (createdByRaw != null) {
      ownerId = createdByRaw.toString();
    }

    final verification = json['verification'];
    return Item(
      id: json['_id'].toString(),
      type: json['type']?.toString() ?? 'lost',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      date: _parseDate(json['date']) ?? DateTime.now(),
      status: json['status']?.toString() ?? 'active',
      claimStatus: json['claimStatus']?.toString() ?? 'none',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      color: json['color']?.toString(),
      brand: json['brand']?.toString(),
      time: json['time']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      createdBy: owner,
      createdById: ownerId,
      verificationQuestion:
          verification is Map ? verification['question']?.toString() : null,
      returnedAt: _parseDate(json['returnedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
