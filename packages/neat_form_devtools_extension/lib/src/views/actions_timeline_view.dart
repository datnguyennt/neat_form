import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neat_form_devtools_extension/src/controllers/devtools_service_controller.dart';
import 'package:neat_form_devtools_extension/src/models/form_event.dart';
import 'package:neat_form_devtools_extension/src/widgets/event_details_dialog.dart';
import 'package:neat_form_devtools_extension/src/widgets/json_import_dialog.dart';

/// Right panel providing quick action triggers and real-time event telemetry timeline.
class ActionsTimelineView extends StatelessWidget {
  const ActionsTimelineView({super.key, required this.controller});

  final DevToolsServiceController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Quick Action Toolbar Section
        _buildActionToolbar(context, theme),
        const Divider(height: 1),

        // Live Event Timeline Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.history, size: 16, color: Colors.blueAccent),
              const SizedBox(width: 6),
              const Text(
                'LIVE EVENT STREAM',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const Spacer(),
              ValueListenableBuilder<List<FormEvent>>(
                valueListenable: controller.eventsNotifier,
                builder: (context, events, _) {
                  return TextButton.icon(
                    icon: const Icon(Icons.clear_all, size: 14),
                    label: Text('Clear (${events.length})', style: const TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    onPressed: events.isEmpty ? null : () => controller.clearEvents(),
                  );
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Events List View
        Expanded(
          child: ValueListenableBuilder<List<FormEvent>>(
            valueListenable: controller.eventsNotifier,
            builder: (context, events, _) {
              if (events.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stream, size: 32, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 8),
                      Text(
                        'Listening for form events...',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: events.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildEventTile(context, event, theme);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionToolbar(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'QUICK ACTIONS & SMART TESTING',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),

          // Row 1: Smart Autofill (Valid vs Boundary)
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.auto_fix_high, size: 15, color: Colors.blueAccent),
                  label: const Text('Fill Valid', style: TextStyle(fontSize: 11.5)),
                  onPressed: () async {
                    final success = await controller.autofillMockData(mode: 'valid');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? '⚡ Auto-filled form with valid data!' : 'Failed to autofill form'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.warning_amber_rounded, size: 15, color: Colors.orange),
                  label: const Text('Fill Boundary', style: TextStyle(fontSize: 11.5)),
                  onPressed: () async {
                    final success = await controller.autofillBoundaryData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? '⚠️ Auto-filled boundary & error test values!' : 'Failed to autofill boundary data'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Validate & Reset
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 15, color: Colors.green),
                  label: const Text('Validate', style: TextStyle(fontSize: 11.5)),
                  onPressed: () async {
                    final success = await controller.validateCurrentForm();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? '🔍 Validation executed.' : 'Validation failed'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 15, color: Colors.orange),
                  label: const Text('Reset', style: TextStyle(fontSize: 11.5)),
                  onPressed: () async {
                    final success = await controller.resetCurrentForm();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? '🔄 Form has been reset.' : 'Reset failed'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 3: Import & Export State
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.file_upload_outlined, size: 15),
                  label: const Text('Import JSON', style: TextStyle(fontSize: 11.5)),
                  onPressed: () {
                    final details = controller.selectedFormNotifier.value;
                    if (details == null) return;

                    JsonImportDialog.show(
                      context,
                      formName: details.name,
                      onImport: (values) => controller.importJsonState(values),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.file_download_outlined, size: 15),
                  label: const Text('Export JSON', style: TextStyle(fontSize: 11.5)),
                  onPressed: () {
                    final details = controller.selectedFormNotifier.value;
                    if (details == null) return;

                    final exportData = {
                      'id': details.id,
                      'name': details.name,
                      'type': details.type,
                      'status': details.status,
                      'isValid': details.isValid,
                      'isTouched': details.isTouched,
                      'fields': details.fields.map((k, v) => MapEntry(k, {
                            'value': v.value,
                            'isValid': v.isValid,
                            'errorMessage': v.errorMessage,
                          })),
                      'itemsCount': details.items.length,
                    };

                    final prettyJson = const JsonEncoder.withIndent('  ').convert(exportData);
                    Clipboard.setData(ClipboardData(text: prettyJson));

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('💾 Form state JSON copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(BuildContext context, FormEvent event, ThemeData theme) {
    final timeStr = _formatTimestamp(event.timestamp);

    Color badgeColor;
    switch (event.kind) {
      case 'form_registered':
        badgeColor = Colors.green;
        break;
      case 'form_unregistered':
        badgeColor = Colors.grey;
        break;
      case 'form_updated':
      case 'form_array_updated':
        badgeColor = Colors.blueAccent;
        break;
      case 'submission_status_changed':
        badgeColor = Colors.purpleAccent;
        break;
      default:
        badgeColor = Colors.blueGrey;
    }

    return InkWell(
      onTap: () => EventDetailsDialog.show(context, event),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    event.kind,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              event.summary,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
