import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neat_form_devtools_extension/src/models/form_event.dart';

/// Modal dialog showing formatted details and JSON payload of a specific form event.
class EventDetailsDialog extends StatelessWidget {
  const EventDetailsDialog({super.key, required this.event});

  final FormEvent event;

  static void show(BuildContext context, FormEvent event) {
    showDialog(
      context: context,
      builder: (context) => EventDetailsDialog(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prettyJson = const JsonEncoder.withIndent('  ').convert(event.data);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Event: ${event.kind}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Form ID: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  event.formId,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                const Spacer(),
                Text(
                  event.timestamp.toIso8601String(),
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'EVENT PAYLOAD',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  prettyJson,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.copy, size: 14),
          label: const Text('Copy JSON'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: prettyJson));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event JSON copied to clipboard'), duration: Duration(seconds: 1)),
            );
          },
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
