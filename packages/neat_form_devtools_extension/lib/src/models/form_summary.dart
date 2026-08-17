/// Represents a summary of an active NeatForm or NeatFormArray instance.
class FormSummary {
  const FormSummary({
    required this.id,
    required this.name,
    required this.type,
    this.fieldsCount = 0,
    this.itemsCount = 0,
    required this.isValid,
    required this.isTouched,
    required this.status,
    required this.createdAt,
  });

  factory FormSummary.fromJson(Map<String, dynamic> json) {
    return FormSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'form',
      fieldsCount: json['fieldsCount'] as int? ?? 0,
      itemsCount: json['itemsCount'] as int? ?? 0,
      isValid: json['isValid'] as bool? ?? true,
      isTouched: json['isTouched'] as bool? ?? false,
      status: json['status'] as String? ?? 'idle',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  final String id;
  final String name;
  final String type;
  final int fieldsCount;
  final int itemsCount;
  final bool isValid;
  final bool isTouched;
  final String status;
  final DateTime createdAt;

  bool get isArray => type == 'array';
}
