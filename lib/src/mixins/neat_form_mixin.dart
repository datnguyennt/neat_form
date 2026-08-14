import 'package:meta/meta.dart';
import 'package:neat_form/src/core/field_state.dart';
import 'package:neat_form/src/core/validation_error.dart';
import 'package:neat_form/src/core/validator.dart';
import 'package:neat_form/src/extensions/form_map_extensions.dart';

/// Mixin to manage declarative, immutable form state in any state manager (Riverpod, Bloc, StateNotifier, etc.).
mixin NeatFormMixin<K> {
  /// The current map of fields in the form state.
  Map<K, NeatFieldState<dynamic>> get fields;

  /// The map of validators configured for this form.
  @protected
  Map<K, NeatValidator<dynamic>> get validators;

  /// Callback to persist updated field states into your state holder (e.g. `state = state.copyWith(...)`).
  @protected
  void updateStateWithFields(Map<K, NeatFieldState<dynamic>> newFields);

  /// Retrieves a field state by key.
  NeatFieldState<T> getField<T>(K key) => fields.getField<T>(key);

  /// Updates a field's value, optionally clears error, and flags touch.
  void setField<T>(
    K key,
    T value, {
    bool touch = true,
    bool clearError = true,
  }) {
    final currentField = fields[key];
    if (currentField == null) {
      throw ArgumentError('Field "$key" not found in form state map');
    }
    final newField = currentField.copyWith(
      value: value,
      error: clearError ? () => null : null,
      showError: clearError ? false : currentField.showError,
      isTouched: touch ? true : currentField.isTouched,
    );

    final newFields = Map<K, NeatFieldState<dynamic>>.from(fields);
    newFields[key] = newField;
    updateStateWithFields(newFields);
  }

  /// Transforms a field using a custom updater function.
  void updateField<T>(
    K key,
    NeatFieldState<T> Function(NeatFieldState<T> current) updater,
  ) {
    final currentField = getField<T>(key);
    final newField = updater(currentField);

    final newFields = Map<K, NeatFieldState<dynamic>>.from(fields);
    newFields[key] = newField;
    updateStateWithFields(newFields);
  }

  /// Sets a field's value and executes validation immediately.
  NeatValidationError? setAndValidateField<T>(
    K key,
    T value, {
    NeatValidator<T>? validator,
    bool touch = true,
  }) {
    final currentField = fields[key];
    if (currentField == null) {
      throw ArgumentError('Field "$key" not found in form state map');
    }
    final validatorToRun =
        validator ?? (validators[key] as NeatValidator<T>?);

    final error = validatorToRun?.call(value);

    final newField = currentField.copyWith(
      value: value,
      error: () => error,
      showError: true,
      isTouched: touch ? true : currentField.isTouched,
      isValidated: true,
    );

    final newFields = Map<K, NeatFieldState<dynamic>>.from(fields);
    newFields[key] = newField;
    updateStateWithFields(newFields);

    return error;
  }

  /// Runs validation on an existing field value and updates its error state.
  NeatValidationError? validateField<T>(
    K key, {
    NeatValidator<T>? validator,
  }) {
    final field = fields[key];
    if (field == null) {
      throw ArgumentError('Field "$key" not found in form state map');
    }
    final validatorToRun = validator ?? validators[key];

    final error = validatorToRun?.call(field.value);

    final newField = field.copyWith(
      error: () => error,
      showError: true,
      isValidated: true,
    );

    final newFields = Map<K, NeatFieldState<dynamic>>.from(fields);
    newFields[key] = newField;
    updateStateWithFields(newFields);

    return error;
  }

  /// Validates an asynchronous rule (e.g. API availability check).
  /// Sets `isValidating = true` during check, and sets error upon completion.
  Future<NeatValidationError?> validateFieldAsync<T>(
    K key,
    NeatAsyncValidator<T> asyncValidator,
  ) async {
    final currentField = getField<T>(key);

    // Set validating state
    updateField<T>(key, (f) => f.copyWith(isValidating: true));

    try {
      final error = await asyncValidator(currentField.value);
      updateField<T>(
        key,
        (f) => f.copyWith(
          error: () => error,
          showError: error != null,
          isValidating: false,
          isValidated: true,
        ),
      );
      return error;
    } catch (_) {
      updateField<T>(key, (f) => f.copyWith(isValidating: false));
      rethrow;
    }
  }

  /// Validates all fields (or a subset of [keys]).
  /// Returns `true` if all validated fields are valid, `false` otherwise.
  bool validateForm([List<K>? keys]) {
    var isValid = true;
    final newFields = Map<K, NeatFieldState<dynamic>>.from(fields);
    final fieldsToValidate = keys ?? validators.keys;

    for (final key in fieldsToValidate) {
      if (newFields.containsKey(key) && validators.containsKey(key)) {
        final field = newFields[key]!;
        final validator = validators[key]!;

        final error = validator(field.value);
        newFields[key] = field.copyWith(
          error: () => error,
          showError: true,
          isValidated: true,
        );

        if (error != null) {
          isValid = false;
        }
      }
    }

    updateStateWithFields(newFields);
    return isValid;
  }

  /// Clears all errors on all fields without modifying their values.
  void clearErrors() {
    final newFields = fields.map(
      (key, field) => MapEntry(
        key,
        field.copyWith(error: () => null, showError: false),
      ),
    );
    updateStateWithFields(newFields);
  }
}
