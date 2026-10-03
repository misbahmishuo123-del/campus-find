import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../models/match_result.dart';
import 'status_chip.dart';

/// Reusable card for showing an item in a list.
class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  final MatchScore? matchScore; // shown on the Possible Matches screen
  final Widget? trailing;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.matchScore,
    this.trailing,
  });

  IconData get _typeIcon =>
      item.isLost ? Icons.report_gmailerrorred : Icons.check_circle_outline;
  Color get _typeColor =>
      item.isLost ? const Color(0xFFC62828) : const Color(0xFF00695C);

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, y').format(item.date);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_typeIcon, color: _typeColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.type.toUpperCase(),
                              style: TextStyle(
                                color: _typeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${item.category}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ),
                  Icon(Icons.event_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(dateStr,
                      style: TextStyle(
                          color: Colors.grey.shade700, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  StatusChip(status: item.status),
                  const Spacer(),
                  if (matchScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${matchScore!.total}% • ${matchScore!.label}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
