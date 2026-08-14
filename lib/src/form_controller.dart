import 'package:flutter/foundation.dart';
import 'package:neat_form/src/field_state.dart';
import 'package:neat_form/src/validators.dart';

/// Abstract observer interface for monitoring form events.
abstract class NeatFormObserver<K> {
  /// Default const constructor for subclasses.
  const NeatFormObserver();

  /// Invoked whenever a field's value changes.
  void onFieldChanged(K key, Object? value) {}

  /// Invoked whenever a field fails validation.
  void onValidationError(K key, NeatValidationError error) {}

  /// Invoked whenever a form submission attempt finishes.
  void onFormSubmitted(Map<K, Object?> values, {required bool isValid}) {}

  /// Invoked whenever the submission status changes (idle, submitting, success, failure).
  void onSubmissionStatusChanged(NeatSubmissionStatus status) {}

  /// Invoked whenever the form or a field is reset to its initial state.
  void onFormReset() {}
}

/// Mixin to manage declarative, immutable form state in any state manager (Riverpod, Bloc, StateNotifier, etc.).
mixin NeatFormMixin<K> {
  final Map<K, int> _asyncValidationTokens = {};
  NeatSubmissionStatus _submissionStatus = NeatSubmissionStatus.idle;

  /// Optional observer for event tracking, analytics, or logging.
  NeatFormObserver<K>? get observer => null;

  /// The current map of fields in the form state.
  Map<K, NeatFieldState<Object?>> get fields;

  /// The current submission status (idle, submitting, success, failure).
  NeatSubmissionStatus get submissionStatus => _submissionStatus;

  /// The map of validators configured for this form.
  @protected
  Map<K, NeatValidator<Object?>> get validators;

  /// Callback to persist updated field states into your state holder (e.g. `state = state.copyWith(...)`).
  @protected
  void updateStateWithFields(Map<K, NeatFieldState<Object?>> newFields);

  /// Updates the submission status and notifies the observer.
  @protected
  void updateSubmissionStatus(NeatSubmissionStatus status) {
    if (_submissionStatus == status) return;
    _submissionStatus = status;
    observer?.onSubmissionStatusChanged(status);
  }

  /// Retrieves a field state by key with strict type safety.
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
      error: clearError ? null : currentField.error,
      showError: !clearError && currentField.showError,
      isTouched: touch || currentField.isTouched,
    );

    final newFields = Map<K, NeatFieldState<Object?>>.from(fields);
    newFields[key] = newField;
    updateStateWithFields(newFields);

    observer?.onFieldChanged(key, value);
  }

  /// Transforms a field using a custom updater function.
  void updateField<T>(
    K key,
    NeatFieldState<T> Function(NeatFieldState<T> current) updater,
  ) {
    final currentField = getField<T>(key);
    final newField = updater(currentField);

    final newFields = Map<K, NeatFieldState<Object?>>.from(fields);
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
    final validatorToRun = validator ?? (validators[key] as NeatValidator<T>?);

    final error = validatorToRun?.call(value);

    final newField = currentField.copyWith(
      value: value,
      error: error,
      showError: true,
      isTouched: touch || currentField.isTouched,
      isValidated: true,
    );

    final newFields = Map<K, NeatFieldState<Object?>>.from(fields);
    newFields[key] = newField;
    updateStateWithFields(newFields);

    observer?.onFieldChanged(key, value);
    if (error != null) {
      observer?.onValidationError(key, error);
    }

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
    final validatorToRun = validator ?? (validators[key] as NeatValidator<T>?);

    final error = validatorToRun?.call(field.value as T?);

    final newField = field.copyWith(
      error: error,
      showError: true,
      isValidated: true,
    );

    final newFields = Map<K, NeatFieldState<Object?>>.from(fields);
    newFields[key] = newField;
    updateStateWithFields(newFields);

    if (error != null) {
      observer?.onValidationError(key, error);
    }

    return error;
  }

  /// Validates an asynchronous rule (e.g. API availability check).
  ///
  /// Uses sequence tokens per field key to prevent race conditions.
  Future<NeatValidationError?> validateFieldAsync<T>(
    K key,
    NeatAsyncValidator<T> asyncValidator,
  ) async {
    final currentField = getField<T>(key);
    final valueAtStart = currentField.value;

    final currentToken = (_asyncValidationTokens[key] ?? 0) + 1;
    _asyncValidationTokens[key] = currentToken;

    updateField<T>(key, (f) => f.copyWith(isValidating: true));

    try {
      final error = await asyncValidator(valueAtStart);

      if (_asyncValidationTokens[key] == currentToken) {
        updateField<T>(
          key,
          (f) => f.copyWith(
            error: error,
            showError: error != null,
            isValidating: false,
            isValidated: true,
          ),
        );
        if (error != null) {
          observer?.onValidationError(key, error);
        }
      } else {
        updateField<T>(key, (f) => f.copyWith(isValidating: false));
      }
      return error;
    } on Exception {
      if (_asyncValidationTokens[key] == currentToken) {
        updateField<T>(key, (f) => f.copyWith(isValidating: false));
      }
      rethrow;
    } catch (_) {
      if (_asyncValidationTokens[key] == currentToken) {
        updateField<T>(key, (f) => f.copyWith(isValidating: false));
      }
      rethrow;
    }
  }

  /// Validates all fields (or a subset of [keys]).
  /// Returns `true` if all validated fields are valid, `false` otherwise.
  bool validateForm([List<K>? keys]) {
    var isValid = true;
    final newFields = Map<K, NeatFieldState<Object?>>.from(fields);
    final fieldsToValidate = keys ?? validators.keys;

    for (final key in fieldsToValidate) {
      if (newFields.containsKey(key) && validators.containsKey(key)) {
        final field = newFields[key]!;
        final validator = validators[key]!;

        final error = validator(field.value);
        newFields[key] = field.copyWith(
          error: error,
          showError: true,
          isValidated: true,
        );

        if (error != null) {
          isValid = false;
          observer?.onValidationError(key, error);
        }
      }
    }

    updateStateWithFields(newFields);
    return isValid;
  }

  /// Submits the form by validating fields and running [onSubmit] if valid.
  /// Automatically manages [submissionStatus] lifecycle and triggers observer events.
  Future<bool> submitForm({
    required Future<void> Function(Map<K, Object?> values) onSubmit,
    void Function(Map<K, NeatValidationError> errors)? onError,
    List<K>? keys,
  }) async {
    updateSubmissionStatus(NeatSubmissionStatus.submitting);

    final isValid = validateForm(keys);
    final values = fields.toValuesMap();

    observer?.onFormSubmitted(values, isValid: isValid);

    if (!isValid) {
      updateSubmissionStatus(NeatSubmissionStatus.failure);
      if (onError != null) {
        final errors = <K, NeatValidationError>{};
        for (final entry in fields.entries) {
          if (entry.value.error != null) {
            errors[entry.key] = entry.value.error!;
          }
        }
        onError(errors);
      }
      return false;
    }

    try {
      await onSubmit(values);
      updateSubmissionStatus(NeatSubmissionStatus.success);
      return true;
    } on Exception {
      updateSubmissionStatus(NeatSubmissionStatus.failure);
      rethrow;
    } catch (_) {
      updateSubmissionStatus(NeatSubmissionStatus.failure);
      rethrow;
    }
  }

  /// Resets a field back to its initial value, clearing errors, touch state, and pending async validations.
  void resetField<T>(K key) {
    _asyncValidationTokens[key] = (_asyncValidationTokens[key] ?? 0) + 1;

    final field = getField<T>(key);
    final reset = field.copyWith(
      value: field.initialValue,
      error: null,
      showError: false,
      isTouched: false,
      isValidating: false,
      isValidated: false,
    );

    final newFields = Map<K, NeatFieldState<Object?>>.from(fields);
    newFields[key] = reset;
    updateStateWithFields(newFields);

    observer?.onFormReset();
  }

  /// Resets all fields back to their initial values, clearing errors, touch states, and pending async validations.
  void resetForm() {
    _asyncValidationTokens.clear();
    updateSubmissionStatus(NeatSubmissionStatus.idle);

    final newFields = fields.map(
      (key, field) => MapEntry(
        key,
        field.copyWith(
          value: field.initialValue,
          error: null,
          showError: false,
          isTouched: false,
          isValidating: false,
          isValidated: false,
        ),
      ),
    );
    updateStateWithFields(newFields);

    observer?.onFormReset();
  }

  /// Clears all errors on all fields without modifying their values.
  void clearErrors() {
    final newFields = fields.map(
      (key, field) => MapEntry(
        key,
        field.copyWith(error: null, showError: false),
      ),
    );
    updateStateWithFields(newFields);
  }
}

/// A Flutter-ready controller for managing form state without third-party state managers.
///
/// Implements Flutter's [Listenable] (via [ChangeNotifier]) so it plugs directly
/// into Flutter's `ListenableBuilder`, `AnimatedBuilder`, or vanilla listeners.
class NeatFormController<K> extends ChangeNotifier with NeatFormMixin<K> {
  /// Creates a form controller with initial fields, optional validators, and observer.
  NeatFormController({
    required Map<K, NeatFieldState<Object?>> initialFields,
    Map<K, NeatValidator<Object?>> validators = const {},
    NeatFormObserver<K>? observer,
  })  : _fields = Map<K, NeatFieldState<Object?>>.from(initialFields),
        _validators = Map<K, NeatValidator<Object?>>.from(validators),
        _observer = observer;

  Map<K, NeatFieldState<Object?>> _fields;
  final Map<K, NeatValidator<Object?>> _validators;
  final NeatFormObserver<K>? _observer;
  bool _isDisposed = false;

  @override
  Map<K, NeatFieldState<Object?>> get fields => Map.unmodifiable(_fields);

  @override
  Map<K, NeatValidator<Object?>> get validators => _validators;

  @override
  NeatFormObserver<K>? get observer => _observer;

  /// Whether this controller has been disposed.
  bool get isDisposed => _isDisposed;

  @override
  void updateStateWithFields(Map<K, NeatFieldState<Object?>> newFields) {
    if (_isDisposed) return;
    _fields = newFields;
    notifyListeners();
  }

  @override
  void updateSubmissionStatus(NeatSubmissionStatus status) {
    if (_isDisposed) return;
    super.updateSubmissionStatus(status);
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// Extension methods for manipulating and querying a map of form fields.
extension NeatFormFieldMapExtension<K> on Map<K, NeatFieldState<Object?>> {
  /// Checks if a field holds a valid real-time state.
  bool isFilledAndValid(K key) {
    final field = this[key];
    if (field == null) return false;

    if (field.isOptional && field.isEmpty) {
      return field.isValid;
    }

    return field.isNotEmpty && field.isValid;
  }

  /// Checks if ALL fields currently in the map are filled and valid.
  bool get areAllFieldsValid {
    if (isEmpty) return false;

    return values.every((field) {
      if (field.isOptional && field.isEmpty) return field.isValid;
      return field.isNotEmpty && field.isValid;
    });
  }

  /// Backward compatible alias for [areAllFieldsValid].
  bool get isAllFieldsValid => areAllFieldsValid;

  /// True if all fields have no errors (regardless of whether they are filled).
  bool get isCleanAndValid {
    return values.every((field) => field.isValid);
  }

  /// Safely gets a strongly typed field state by key.
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
  Map<K, Object?> toValuesMap() {
    return map((key, field) => MapEntry(key, field.value));
  }
}
