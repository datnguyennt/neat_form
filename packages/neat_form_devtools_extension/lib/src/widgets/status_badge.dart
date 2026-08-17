import 'package:flutter/material.dart';

/// Reusable badge widget indicating validation, submission, or touch status.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.valid() {
    return const StatusBadge(
      label: 'Valid',
      color: Colors.green,
      icon: Icons.check_circle_outline,
    );
  }

  factory StatusBadge.invalid([String? label]) {
    return StatusBadge(
      label: label ?? 'Invalid',
      color: Colors.redAccent,
      icon: Icons.cancel_outlined,
    );
  }

  factory StatusBadge.validating() {
    return const StatusBadge(
      label: 'Validating',
      color: Colors.blueAccent,
      icon: Icons.sync,
    );
  }

  factory StatusBadge.touched(bool touched) {
    return StatusBadge(
      label: touched ? 'Touched' : 'Untouched',
      color: touched ? Colors.orange : Colors.grey,
      icon: touched ? Icons.touch_app_outlined : Icons.pan_tool_outlined,
    );
  }

  factory StatusBadge.optional() {
    return const StatusBadge(
      label: 'Optional',
      color: Colors.purple,
      icon: Icons.info_outline,
    );
  }

  factory StatusBadge.status(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'submitting':
        color = Colors.blue;
        icon = Icons.hourglass_top_outlined;
        break;
      case 'success':
        color = Colors.green;
        icon = Icons.done_all;
        break;
      case 'failure':
        color = Colors.red;
        icon = Icons.error_outline;
        break;
      case 'idle':
      default:
        color = Colors.blueGrey;
        icon = Icons.pause_circle_outline;
        break;
    }

    return StatusBadge(
      label: status.toUpperCase(),
      color: color,
      icon: icon,
    );
  }

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
