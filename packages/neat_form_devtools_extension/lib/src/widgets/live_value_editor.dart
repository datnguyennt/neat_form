import 'package:flutter/material.dart';

/// Modal dialog allowing the developer to override a field's value live on the running app.
class LiveValueEditorDialog extends StatefulWidget {
  const LiveValueEditorDialog({
    super.key,
    required this.fieldKey,
    required this.currentValue,
    required this.onApply,
  });

  final String fieldKey;
  final dynamic currentValue;
  final Future<bool> Function(dynamic newValue) onApply;

  static Future<void> show(
    BuildContext context, {
    required String fieldKey,
    required dynamic currentValue,
    required Future<bool> Function(dynamic newValue) onApply,
  }) {
    return showDialog(
      context: context,
      builder: (context) => LiveValueEditorDialog(
        fieldKey: fieldKey,
        currentValue: currentValue,
        onApply: onApply,
      ),
    );
  }

  @override
  State<LiveValueEditorDialog> createState() => _LiveValueEditorDialogState();
}

class _LiveValueEditorDialogState extends State<LiveValueEditorDialog> {
  late final TextEditingController textController;
  late bool isBoolean;
  late bool boolValue;
  bool isSubmitting = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    isBoolean = widget.currentValue is bool;
    boolValue = isBoolean ? widget.currentValue as bool : false;
    textController = TextEditingController(
      text: widget.currentValue != null ? widget.currentValue.toString() : '',
    );
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    dynamic targetValue;
    if (isBoolean) {
      targetValue = boolValue;
    } else {
      final raw = textController.text;
      if (raw.toLowerCase() == 'true') {
        targetValue = true;
      } else if (raw.toLowerCase() == 'false') {
        targetValue = false;
      } else if (int.tryParse(raw) != null) {
        targetValue = int.parse(raw);
      } else if (double.tryParse(raw) != null) {
        targetValue = double.parse(raw);
      } else {
        targetValue = raw;
      }
    }

    final success = await widget.onApply(targetValue);
    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          isSubmitting = false;
          errorMessage = 'Failed to apply value update.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit_note, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Override Field: ${widget.fieldKey}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inject a new value directly into the running application to test reactivity & validation.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (isBoolean) ...[
              Row(
                children: [
                  const Text('Value (Boolean):', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Switch(
                    value: boolValue,
                    onChanged: isSubmitting ? null : (v) => setState(() => boolValue = v),
                  ),
                  Text(boolValue ? 'TRUE' : 'FALSE', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ] else ...[
              TextField(
                controller: textController,
                autofocus: true,
                enabled: !isSubmitting,
                decoration: InputDecoration(
                  labelText: 'New Value',
                  hintText: 'Enter new string, number, or boolean...',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => textController.clear(),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isSubmitting ? null : _submit,
          child: isSubmitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Apply Changes'),
        ),
      ],
    );
  }
}
