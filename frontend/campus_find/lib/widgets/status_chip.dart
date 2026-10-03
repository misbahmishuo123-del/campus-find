import 'package:flutter/material.dart';

/// A small colored chip used to display item / claim statuses consistently.
class StatusChip extends StatelessWidget {
  final String status;
  final String? prefixLabel;

  const StatusChip({super.key, required this.status, this.prefixLabel});

  static const Map<String, Color> _colors = {
    'active': Color(0xFF1B5E20),
    'matched': Color(0xFF00695C),
    'claimed': Color(0xFFEF6C00),
    'verified': Color(0xFF283593),
    'returned': Color(0xFF455A64),
    'closed': Color(0xFF616161),
    'pending': Color(0xFFEF6C00),
    'approved': Color(0xFF1B5E20),
    'rejected': Color(0xFFC62828),
    'lost': Color(0xFFC62828),
    'found': Color(0xFF00695C),
    'none': Color(0xFF616161),
  };

  Color get _bg => (_colors[status.toLowerCase()] ?? Colors.grey.shade700)
      .withOpacity(0.12);
  Color get _fg => _colors[status.toLowerCase()] ?? Colors.grey.shade800;

  String get _label {
    final text = status[0].toUpperCase() + status.substring(1);
    return prefixLabel == null ? text : '$prefixLabel $text';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: _fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(
              color: _fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
