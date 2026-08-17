import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neat_form_devtools_extension/src/controllers/devtools_service_controller.dart';
import 'package:neat_form_devtools_extension/src/models/form_details.dart';
import 'package:neat_form_devtools_extension/src/widgets/live_value_editor.dart';
import 'package:neat_form_devtools_extension/src/widgets/status_badge.dart';

/// Center panel providing in-depth inspection and live editing of fields.
class FieldInspectorView extends StatelessWidget {
  const FieldInspectorView({super.key, required this.controller});

  final DevToolsServiceController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<FormDetails?>(
      valueListenable: controller.selectedFormNotifier,
      builder: (context, details, _) {
        if (details == null) {
          return const Center(
            child: Text(
              'Select a form from the left panel to inspect its fields.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Form Header Card
            _buildFormHeaderCard(context, details, theme),
            const SizedBox(height: 16),

            // Standard Form vs Array Form Content
            if (details.isArray)
              _buildArrayInspector(context, details, theme)
            else
              _buildStandardFieldsInspector(context, details, theme),
          ],
        );
      },
    );
  }

  Widget _buildFormHeaderCard(
    BuildContext context,
    FormDetails details,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                details.isArray ? Icons.list_alt : Icons.assignment_outlined,
                color: details.isValid ? Colors.green : Colors.redAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  details.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StatusBadge.status(details.status),
              const SizedBox(width: 6),
              if (details.isValid) StatusBadge.valid() else StatusBadge.invalid(),
              const SizedBox(width: 6),
              StatusBadge.touched(details.isTouched),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'ID: ${details.id}',
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'monospace'),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 14),
                tooltip: 'Copy Form ID',
                splashRadius: 16,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: details.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Form ID copied to clipboard'), duration: Duration(seconds: 1)),
                  );
                },
              ),
              const Spacer(),
              Text(
                'Type: ${details.type.toUpperCase()}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStandardFieldsInspector(
    BuildContext context,
    FormDetails details,
    ThemeData theme,
  ) {
    final fields = details.fields.values.toList();
    final validCount = fields.where((f) => f.isValid).length;
    final errorCount = fields.where((f) => !f.isValid).length;
    final touchedCount = fields.where((f) => f.isTouched).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Metrics Bar
        Row(
          children: [
            _buildMetricTile('Total Fields', '${fields.length}', Colors.blueAccent, theme),
            const SizedBox(width: 10),
            _buildMetricTile('Valid', '$validCount', Colors.green, theme),
            const SizedBox(width: 10),
            _buildMetricTile('Errors', '$errorCount', Colors.redAccent, theme),
            const SizedBox(width: 10),
            _buildMetricTile('Touched', '$touchedCount', Colors.orange, theme),
          ],
        ),
        const SizedBox(height: 18),

        Row(
          children: [
            const Text(
              'FIELDS & VALIDATION STATE',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const Spacer(),
            Text(
              'Click "Edit" on any field to inject values live',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (fields.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No fields configured on this form.')),
          )
        else
          ...fields.map((field) => _buildFieldCard(context, field, theme)),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, Color color, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard(
    BuildContext context,
    FieldDetails field,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: field.isValid
              ? theme.dividerColor.withValues(alpha: 0.2)
              : Colors.redAccent.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    field.key,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(width: 8),
                if (field.isOptional) StatusBadge.optional(),
                const SizedBox(width: 6),
                if (field.isValidating)
                  StatusBadge.validating()
                else if (field.isValid)
                  StatusBadge.valid()
                else
                  StatusBadge.invalid(),
                const SizedBox(width: 6),
                StatusBadge.touched(field.isTouched),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit Value', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: () {
                    LiveValueEditorDialog.show(
                      context,
                      fieldKey: field.key,
                      currentValue: field.value,
                      onApply: (newValue) => controller.setFieldValue(field.key, newValue),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Current Value: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      field.value == null ? '<null>' : '${field.value}',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: field.value == null ? FontStyle.italic : null,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            if (field.errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        field.errorMessage!,
                        style: const TextStyle(fontSize: 11.5, color: Colors.redAccent, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (field.errorCode != null)
                      Text(
                        '[code: ${field.errorCode}]',
                        style: TextStyle(fontSize: 10, color: Colors.redAccent.withValues(alpha: 0.8), fontFamily: 'monospace'),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildArrayInspector(
    BuildContext context,
    FormDetails details,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildMetricTile('Array Length', '${details.items.length}', Colors.blueAccent, theme),
            const SizedBox(width: 10),
            _buildMetricTile('Array Status', details.status.toUpperCase(), Colors.green, theme),
          ],
        ),
        if (details.error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.redAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Array Error: ${details.error}',
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        Text(
          'ARRAY ITEMS (${details.items.length})',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),

        if (details.items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Array has 0 items.')),
          )
        else
          ...details.items.map((item) => _buildArrayItemCard(context, item, theme)),
      ],
    );
  }

  Widget _buildArrayItemCard(
    BuildContext context,
    ArrayItemDetails item,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: item.isValid ? theme.dividerColor.withValues(alpha: 0.2) : Colors.redAccent.withValues(alpha: 0.4),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(
          Icons.folder_outlined,
          color: item.isValid ? Colors.green : Colors.redAccent,
          size: 20,
        ),
        title: Text(
          'Item #${item.index} (id: ${item.id})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          '${item.fields.length} subfields • ${item.isValid ? "Valid" : "Has Errors"}',
          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
        ),
        children: item.fields.values.map((f) => _buildFieldCard(context, f, theme)).toList(),
      ),
    );
  }
}
