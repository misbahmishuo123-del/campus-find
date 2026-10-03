class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String? itemId;
  final String? claimId;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
    this.itemId,
    this.claimId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'].toString(),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      read: json['read'] == true,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      itemId: json['itemId']?.toString(),
      claimId: json['claimId']?.toString(),
    );
  }
}
