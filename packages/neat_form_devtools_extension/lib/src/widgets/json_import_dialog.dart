import 'dart:convert';

import 'package:flutter/material.dart';

/// Modal dialog that allows importing a JSON state snapshot to recreate form conditions live.
class JsonImportDialog extends StatefulWidget {
  const JsonImportDialog({
    super.key,
    required this.formName,
    required this.onImport,
  });

  final String formName;
  final Future<bool> Function(Map<String, dynamic> values) onImport;

  static Future<void> show(
    BuildContext context, {
    required String formName,
    required Future<bool> Function(Map<String, dynamic> values) onImport,
  }) {
    return showDialog(
      context: context,
      builder: (context) => JsonImportDialog(
        formName: formName,
        onImport: onImport,
      ),
    );
  }

  @override
  State<JsonImportDialog> createState() => _JsonImportDialogState();
}

class _JsonImportDialogState extends State<JsonImportDialog> {
  final TextEditingController jsonTextController = TextEditingController();
  bool isSubmitting = false;
  String? parseError;

  @override
  void dispose() {
    jsonTextController.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final text = jsonTextController.text.trim();
    if (text.isEmpty) {
      setState(() => parseError = 'Please enter JSON data');
      return;
    }

    Map<String, dynamic> parsed;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        parsed = decoded;
      } else if (decoded is Map) {
        parsed = decoded.cast<String, dynamic>();
      } else {
        setState(() => parseError = 'JSON root must be an Object (Key-Value map)');
        return;
      }
    } on Object catch (e) {
      setState(() => parseError = 'Invalid JSON: $e');
      return;
    }

    setState(() {
      isSubmitting = true;
      parseError = null;
    });

    final success = await widget.onImport(parsed);
    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ Form state successfully restored from JSON!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          isSubmitting = false;
          parseError = 'Failed to apply state to form.';
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
          const Icon(Icons.file_upload_outlined, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Import JSON State: ${widget.formName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste a JSON state snapshot to bulk-update all fields and recreate specific edge cases or bug scenarios.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: jsonTextController,
              maxLines: 8,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: '{\n  "email": "user@domain.com",\n  "password": "secret"\n}',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12),
                errorText: parseError,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.bolt, size: 16),
          label: isSubmitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Restore State'),
          onPressed: isSubmitting ? null : _apply,
        ),
      ],
    );
  }
}
