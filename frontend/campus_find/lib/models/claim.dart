import 'item.dart';
import 'user.dart';

class Claim {
  final String id;
  final String itemId;
  final Item? item;
  final String claimantId;
  final AppUser? claimant;
  final String reason;
  final String status; // pending | approved | rejected
  final String? adminNotes;
  final bool? verificationMatched;
  final DateTime createdAt;

  Claim({
    required this.id,
    required this.itemId,
    required this.claimantId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.item,
    this.claimant,
    this.adminNotes,
    this.verificationMatched,
  });

  factory Claim.fromJson(Map<String, dynamic> json) {
    final itemRaw = json['itemId'];
    Item? item;
    String itemId = '';
    if (itemRaw is Map<String, dynamic>) {
      item = Item.fromJson(itemRaw);
      itemId = item.id;
    } else if (itemRaw != null) {
      itemId = itemRaw.toString();
    }

    final claimantRaw = json['claimantId'];
    AppUser? claimant;
    String claimantId = '';
    if (claimantRaw is Map<String, dynamic>) {
      claimant = AppUser.fromJson(claimantRaw);
      claimantId = claimant.id;
    } else if (claimantRaw != null) {
      claimantId = claimantRaw.toString();
    }

    return Claim(
      id: json['_id'].toString(),
      itemId: itemId,
      item: item,
      claimantId: claimantId,
      claimant: claimant,
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      adminNotes: json['adminNotes']?.toString(),
      verificationMatched: json['verificationMatched'] as bool?,
    );
  }
}
