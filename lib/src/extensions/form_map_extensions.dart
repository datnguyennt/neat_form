import 'package:neat_form/src/core/field_state.dart';
import 'package:neat_form/src/core/validation_error.dart';

/// Extension methods for manipulating and querying a map of form fields.
extension NeatFormFieldMapExtension<K> on Map<K, NeatFieldState<dynamic>> {
  /// Checks if a field holds a valid real-time state.
  /// Optional fields with empty values are considered valid.
  /// Required fields must be non-empty and valid.
  bool isFilledAndValid(K key) {
    final field = this[key];
    if (field == null) return false;

    if (field.isOptional && field.isEmpty) {
      return field.isValid;
    }

    return field.isNotEmpty && field.isValid;
  }

  /// Checks if ALL fields currently in the map are filled and valid.
  bool get isAllFieldsValid {
    if (isEmpty) return false;

    return values.every((field) {
      if (field.isOptional && field.isEmpty) return field.isValid;
      return field.isNotEmpty && field.isValid;
    });
  }

  /// True if all fields have no errors (regardless of whether they are filled).
  bool get isCleanAndValid {
    return values.every((field) => field.isValid);
  }

  /// Safely gets a strongly typed field state by key.
  /// If the field was stored as `NeatFieldState<dynamic>` or nullable type,
  /// it adapts cleanly to `NeatFieldState<T>`.
  NeatFieldState<T> getField<T>(K key) {
    final field = this[key];
    if (field == null) {
      throw ArgumentError('Field "$key" not found in form state map');
    }
    if (field is NeatFieldState<T>) {
      return field;
    }
    return NeatFieldState<T>(
      value: field.value as T,
      error: field.error,
      showError: field.showError,
      isTouched: field.isTouched,
      isOptional: field.isOptional,
      isValidating: field.isValidating,
      isValidated: field.isValidated,
      initialValue: field.initialValue as T?,
    );
  }

  /// Gets the raw value of a field. Returns null if field doesn't exist.
  T? valueOf<T>(K key) {
    final field = this[key];
    if (field == null) return null;
    return field.value as T?;
  }

  /// Gets the error of a field. Returns null if valid or field doesn't exist.
  NeatValidationError? errorOf(K key) {
    return this[key]?.error;
  }

  /// Exports all field keys and their current values as a raw Map.
  Map<K, dynamic> toValuesMap() {
    return map((key, field) => MapEntry(key, field.value));
  }
}
