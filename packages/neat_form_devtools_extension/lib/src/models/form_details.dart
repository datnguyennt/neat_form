/// Detailed snapshot of a single field within a NeatForm.
class FieldDetails {
  const FieldDetails({
    required this.key,
    required this.value,
    this.initialValue,
    required this.isValid,
    required this.isInvalid,
    required this.isTouched,
    this.isOptional = false,
    this.isValidating = false,
    this.isValidated = false,
    this.showError = false,
    this.errorMessage,
    this.errorCode,
    this.errorParams,
  });

  factory FieldDetails.fromJson(Map<String, dynamic> json) {
    return FieldDetails(
      key: json['key'] as String? ?? '',
      value: json['value'],
      initialValue: json['initialValue'],
      isValid: json['isValid'] as bool? ?? true,
      isInvalid: json['isInvalid'] as bool? ?? false,
      isTouched: json['isTouched'] as bool? ?? false,
      isOptional: json['isOptional'] as bool? ?? false,
      isValidating: json['isValidating'] as bool? ?? false,
      isValidated: json['isValidated'] as bool? ?? false,
      showError: json['showError'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
      errorCode: json['errorCode'] as String?,
      errorParams: json['errorParams'] as Map<String, dynamic>?,
    );
  }

  final String key;
  final dynamic value;
  final dynamic initialValue;
  final bool isValid;
  final bool isInvalid;
  final bool isTouched;
  final bool isOptional;
  final bool isValidating;
  final bool isValidated;
  final bool showError;
  final String? errorMessage;
  final String? errorCode;
  final Map<String, dynamic>? errorParams;
}

/// Detailed snapshot of a single sub-form item in a NeatFormArray.
class ArrayItemDetails {
  const ArrayItemDetails({
    required this.id,
    required this.index,
    required this.isValid,
    required this.isTouched,
    required this.fields,
  });

  factory ArrayItemDetails.fromJson(Map<String, dynamic> json) {
    final fieldsJson = json['fields'] as Map<String, dynamic>? ?? {};
    final parsedFields = fieldsJson.map(
      (k, v) => MapEntry(k, FieldDetails.fromJson(v as Map<String, dynamic>)),
    );

    return ArrayItemDetails(
      id: json['id'] as String? ?? '',
      index: json['index'] as int? ?? 0,
      isValid: json['isValid'] as bool? ?? true,
      isTouched: json['isTouched'] as bool? ?? false,
      fields: parsedFields,
    );
  }

  final String id;
  final int index;
  final bool isValid;
  final bool isTouched;
  final Map<String, FieldDetails> fields;
}

/// Full details of a selected form or dynamic array.
class FormDetails {
  const FormDetails({
    required this.id,
    required this.name,
    required this.type,
    required this.isValid,
    required this.isTouched,
    required this.status,
    this.error,
    this.fields = const {},
    this.items = const [],
    required this.createdAt,
  });

  factory FormDetails.fromJson(Map<String, dynamic> json) {
    final fieldsJson = json['fields'] as Map<String, dynamic>? ?? {};
    final parsedFields = fieldsJson.map(
      (k, v) => MapEntry(k, FieldDetails.fromJson(v as Map<String, dynamic>)),
    );

    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final parsedItems = itemsJson
        .map((e) => ArrayItemDetails.fromJson(e as Map<String, dynamic>))
        .toList();

    return FormDetails(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'form',
      isValid: json['isValid'] as bool? ?? true,
      isTouched: json['isTouched'] as bool? ?? false,
      status: json['status'] as String? ?? 'idle',
      error: json['error'] as String?,
      fields: parsedFields,
      items: parsedItems,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  final String id;
  final String name;
  final String type;
  final bool isValid;
  final bool isTouched;
  final String status;
  final String? error;
  final Map<String, FieldDetails> fields;
  final List<ArrayItemDetails> items;
  final DateTime createdAt;

  bool get isArray => type == 'array';
}
