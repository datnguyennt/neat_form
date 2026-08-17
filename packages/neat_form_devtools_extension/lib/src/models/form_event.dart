/// Represents a real-time event received from the NeatForm engine via VM Service.
class FormEvent {
  const FormEvent({
    required this.kind,
    required this.formId,
    required this.timestamp,
    required this.data,
  });

  factory FormEvent.fromJson(Map<String, dynamic> json) {
    return FormEvent(
      kind: json['kind'] as String? ?? 'unknown',
      formId: json['formId'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
      data: json,
    );
  }

  final String kind;
  final String formId;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  String get summary {
    switch (kind) {
      case 'form_registered':
        return 'Registered form: ${data['name']}';
      case 'form_unregistered':
        return 'Disposed form: $formId';
      case 'form_updated':
        return 'Updated state (valid: ${data['isValid']}, touched: ${data['isTouched']})';
      case 'form_array_updated':
        return 'Array updated (items: ${data['length']}, valid: ${data['isValid']})';
      case 'submission_status_changed':
        return 'Status changed -> ${data['status']}';
      default:
        return '$kind (${data.keys.length} props)';
    }
  }
}
