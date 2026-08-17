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

/// Internal engine encapsulating shared form operations across all state mixins and controllers.
class _NeatFormEngine {
  static NeatFieldState<T> getField<T, K>(
    Map<K, NeatFieldState<Object?>> fields,
    K key,
  ) =>
      fields.getField<T>(key);

  static void setField<T, K>({
    required Map<K, NeatFieldState<Object?>> fields,
    required void Function(Map<K, NeatFieldState<Object?>>) updateFields,
    required NeatFormObserver<K>? observer,
    required K key,
    required T value,
    required bool touch,
    required bool clearError,
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
    updateFields(newFields);

    observer?.onFieldChanged(key, value);
  }

  static void updateField<T, K>({
    required Map<K, NeatFieldState<Object?>> fields,
    required void Function(Map<K, NeatFieldState<Object?>>) updateFields,
    required K key,
    required NeatFieldState<T> Function(NeatFieldState<T> current) updater,
  }) {
    final currentField = fields.getField<T>(key);
    final newField = updater(currentField);

    final newFields = Map<K, NeatFieldState<Object?>>.from(fields);
    newFields[key] = newField;
    updateFields(newFields);
  }

  static NeatValidationError? setAndValidateField<T, K>({
    required Map<K, NeatFieldState<Object?>> fields,
    required Map<K, NeatValidator<Object?>> validators,
    required void Function(Map<K, NeatFieldState<Object?>>) updateFields,
    required NeatFormObserver<K>? observer,
    required K key,
    required T value,
    required NeatValidator<T>? validator,
    required bool touch,
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
    updateFields(newFields);

    observer?.onFieldChanged(key, value);
    if (error != null) {
      observer?.onValidationError(key, error);
    }

    return error;
  }

  static NeatValidationError? validateField<T, K>({
    required Map<K, NeatFieldState<Object?>> fields,
    required Map<K, NeatValidator<Object?>> validators,
    required void Function(Map<K, NeatFieldState<Object?>>) updateFields,
    required NeatFormObserver<K>? observer,
    required K key,
    required NeatValidator<T>? validator,
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
    updateFields(newFields);

    if (error != null) {
      observer?.onValidationError(key, error);
    }

    return error;
  }

  static Future<NeatValidationError?> validateFieldAsync<T, K>({
    required Map<K, int> asyncTokens,
    required Map<K, NeatFieldState<Object?>> fields,
    required void Function(K, NeatFieldState<T> Function(NeatFieldState<T>))
        updateField,
    required NeatFormObserver<K>? observer,
    required K key,
    required NeatAsyncValidator<T> asyncValidator,
  }) async {
    final currentField = fields.getField<T>(key);
    final valueAtStart = currentField.value;

    final currentToken = (asyncTokens[key] ?? 0) + 1;
    asyncTokens[key] = currentToken;

    updateField(key, (f) => f.copyWith(isValidating: true));

    try {
      final error = await asyncValidator(valueAtStart);

      if (asyncTokens[key] == currentToken) {
        updateField(
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
        updateField(key, (f) => f.copyWith(isValidating: false));
      }
      return error;
    } on Exception {
      if (asyncTokens[key] == currentToken) {
        updateField(key, (f) => f.copyWith(isValidating: false));
      }
      rethrow;
    } catch (_) {
      if (asyncTokens[key] == currentToken) {
        updateField(key, (f) => f.copyWith(isValidating: false));
      }
      rethrow;
    }
  }

  static bool validateForm<K>({
    required Map<K, NeatFieldState<Object?>> fields,
    required Map<K, NeatValidator<Object?>> validators,
    required void Function(Map<K, NeatFieldState<Object?>>) updateFields,
    required NeatFormObserver<K>? observer,
    List<K>? keys,
  }) {
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

    updateFields(newFields);
    return isValid;
  }

  static Future<bool> submitForm<K>({
    required bool Function([List<K>?]) validateForm,
    required void Function(NeatSubmissionStatus) updateSubmissionStatus,
    required Map<K, NeatFieldState<Object?>> Function() getFields,
    required NeatFormObserver<K>? observer,
    required Future<void> Function(Map<K, Object?> values) onSubmit,
    void Function(Map<K, NeatValidationError> errors)? onError,
    List<K>? keys,
  }) async {
    updateSubmissionStatus(NeatSubmissionStatus.submitting);

    final isValid = validateForm(keys);
    final currentFields = getFields();
    final values = currentFields.toValuesMap();

    observer?.onFormSubmitted(values, isValid: isValid);

    if (!isValid) {
      updateSubmissionStatus(NeatSubmissionStatus.failure);
      if (onError != null) {
        final errors = <K, NeatValidationError>{};
        for (final entry in currentFields.entries) {
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

  static void resetField<T, K>({
    required Map<K, int> asyncTokens,
    required Map<K, NeatFieldState<Object?>> fields,
    required void Function(Map<K, NeatFieldState<Object?>>) updateFields,
    required NeatFormObserver<K>? observer,
    required K key,
  }) {
    asyncTokens[key] = (asyncTokens[key] ?? 0) + 1;

    final field = fields.getField<T>(key);
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
    updateFields(newFields);

    observer?.onFormReset();
  }

  static void resetForm<K>({
    required Map<K, int> asyncTokens,
    required void Function(NeatSubmissionStatus) updateSubmissionStatus,
    required Map<K, NeatFieldState<Object?>> fields,
    required void Function(Map<K, NeatFieldState<Object?>>) updateFields,
    required NeatFormObserver<K>? observer,
  }) {
    asyncTokens.clear();
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
    updateFields(newFields);

    observer?.onFormReset();
  }

  static void clearErrors<K>({
    required Map<K, NeatFieldState<Object?>> fields,
    required void Function(Map<K, NeatFieldState<Object?>>) updateFields,
  }) {
    final newFields = fields.map(
      (key, field) => MapEntry(
        key,
        field.copyWith(error: null, showError: false),
      ),
    );
    updateFields(newFields);
  }
}

/// Base mixin to manage declarative, immutable form state in any state holder or custom architecture.
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
  NeatFieldState<T> getField<T>(K key) =>
      _NeatFormEngine.getField<T, K>(fields, key);

  /// Updates a field's value, optionally clears error, and flags touch.
  void setField<T>(
    K key,
    T value, {
    bool touch = true,
    bool clearError = true,
  }) =>
      _NeatFormEngine.setField<T, K>(
        fields: fields,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
        value: value,
        touch: touch,
        clearError: clearError,
      );

  /// Transforms a field using a custom updater function.
  void updateField<T>(
    K key,
    NeatFieldState<T> Function(NeatFieldState<T> current) updater,
  ) =>
      _NeatFormEngine.updateField<T, K>(
        fields: fields,
        updateFields: updateStateWithFields,
        key: key,
        updater: updater,
      );

  /// Sets a field's value and executes validation immediately.
  NeatValidationError? setAndValidateField<T>(
    K key,
    T value, {
    NeatValidator<T>? validator,
    bool touch = true,
  }) =>
      _NeatFormEngine.setAndValidateField<T, K>(
        fields: fields,
        validators: validators,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
        value: value,
        validator: validator,
        touch: touch,
      );

  /// Runs validation on an existing field value and updates its error state.
  NeatValidationError? validateField<T>(
    K key, {
    NeatValidator<T>? validator,
  }) =>
      _NeatFormEngine.validateField<T, K>(
        fields: fields,
        validators: validators,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
        validator: validator,
      );

  /// Validates an asynchronous rule (e.g. API availability check).
  Future<NeatValidationError?> validateFieldAsync<T>(
    K key,
    NeatAsyncValidator<T> asyncValidator,
  ) =>
      _NeatFormEngine.validateFieldAsync<T, K>(
        asyncTokens: _asyncValidationTokens,
        fields: fields,
        updateField: updateField,
        observer: observer,
        key: key,
        asyncValidator: asyncValidator,
      );

  /// Validates all fields (or a subset of [keys]).
  bool validateForm([List<K>? keys]) => _NeatFormEngine.validateForm<K>(
        fields: fields,
        validators: validators,
        updateFields: updateStateWithFields,
        observer: observer,
        keys: keys,
      );

  /// Submits the form by validating fields and running [onSubmit] if valid.
  Future<bool> submitForm({
    required Future<void> Function(Map<K, Object?> values) onSubmit,
    void Function(Map<K, NeatValidationError> errors)? onError,
    List<K>? keys,
  }) =>
      _NeatFormEngine.submitForm<K>(
        validateForm: validateForm,
        updateSubmissionStatus: updateSubmissionStatus,
        getFields: () => fields,
        observer: observer,
        onSubmit: onSubmit,
        onError: onError,
        keys: keys,
      );

  /// Resets a field back to its initial value.
  void resetField<T>(K key) => _NeatFormEngine.resetField<T, K>(
        asyncTokens: _asyncValidationTokens,
        fields: fields,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
      );

  /// Resets all fields back to their initial values.
  void resetForm() => _NeatFormEngine.resetForm<K>(
        asyncTokens: _asyncValidationTokens,
        updateSubmissionStatus: updateSubmissionStatus,
        fields: fields,
        updateFields: updateStateWithFields,
        observer: observer,
      );

  /// Clears all errors on all fields without modifying their values.
  void clearErrors() => _NeatFormEngine.clearErrors<K>(
        fields: fields,
        updateFields: updateStateWithFields,
      );
}

/// A standalone mixin for **Riverpod** (`Notifier<NeatFormState<K>>`), **AutoDisposeNotifier**,
/// or **StateNotifier** holding a standalone [NeatFormState<K>].
///
/// Simply add `with NeatFormNotifierMixin<K>` to your Notifier.
mixin NeatFormNotifierMixin<K> {
  final Map<K, int> _asyncValidationTokens = {};

  /// The current state of the form holder (e.g. Riverpod `state`).
  NeatFormState<K> get state;

  /// Setter to update the state of the form holder (e.g. Riverpod `state = ...`).
  set state(NeatFormState<K> value);

  /// Optional observer for event tracking, analytics, or logging.
  NeatFormObserver<K>? get observer => null;

  /// The current map of fields in the form state.
  Map<K, NeatFieldState<Object?>> get fields => state.fields;

  /// The current submission status (idle, submitting, success, failure).
  NeatSubmissionStatus get submissionStatus => state.status;

  /// The map of validators configured for this form.
  @protected
  Map<K, NeatValidator<Object?>> get validators;

  /// Updates the submission status and notifies the observer.
  @protected
  void updateSubmissionStatus(NeatSubmissionStatus status) {
    if (state.status == status) return;
    state = state.copyWith(status: status);
    observer?.onSubmissionStatusChanged(status);
  }

  /// Updates field states in the form.
  @protected
  void updateStateWithFields(Map<K, NeatFieldState<Object?>> newFields) {
    state = state.copyWith(fields: newFields);
  }

  /// Retrieves a field state by key with strict type safety.
  NeatFieldState<T> getField<T>(K key) =>
      _NeatFormEngine.getField<T, K>(fields, key);

  /// Updates a field's value, optionally clears error, and flags touch.
  void setField<T>(
    K key,
    T value, {
    bool touch = true,
    bool clearError = true,
  }) =>
      _NeatFormEngine.setField<T, K>(
        fields: fields,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
        value: value,
        touch: touch,
        clearError: clearError,
      );

  /// Transforms a field using a custom updater function.
  void updateField<T>(
    K key,
    NeatFieldState<T> Function(NeatFieldState<T> current) updater,
  ) =>
      _NeatFormEngine.updateField<T, K>(
        fields: fields,
        updateFields: updateStateWithFields,
        key: key,
        updater: updater,
      );

  /// Sets a field's value and executes validation immediately.
  NeatValidationError? setAndValidateField<T>(
    K key,
    T value, {
    NeatValidator<T>? validator,
    bool touch = true,
  }) =>
      _NeatFormEngine.setAndValidateField<T, K>(
        fields: fields,
        validators: validators,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
        value: value,
        validator: validator,
        touch: touch,
      );

  /// Runs validation on an existing field value and updates its error state.
  NeatValidationError? validateField<T>(
    K key, {
    NeatValidator<T>? validator,
  }) =>
      _NeatFormEngine.validateField<T, K>(
        fields: fields,
        validators: validators,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
        validator: validator,
      );

  /// Validates an asynchronous rule (e.g. API availability check).
  Future<NeatValidationError?> validateFieldAsync<T>(
    K key,
    NeatAsyncValidator<T> asyncValidator,
  ) =>
      _NeatFormEngine.validateFieldAsync<T, K>(
        asyncTokens: _asyncValidationTokens,
        fields: fields,
        updateField: updateField,
        observer: observer,
        key: key,
        asyncValidator: asyncValidator,
      );

  /// Validates all fields (or a subset of [keys]).
  bool validateForm([List<K>? keys]) => _NeatFormEngine.validateForm<K>(
        fields: fields,
        validators: validators,
        updateFields: updateStateWithFields,
        observer: observer,
        keys: keys,
      );

  /// Submits the form by validating fields and running [onSubmit] if valid.
  Future<bool> submitForm({
    required Future<void> Function(Map<K, Object?> values) onSubmit,
    void Function(Map<K, NeatValidationError> errors)? onError,
    List<K>? keys,
  }) =>
      _NeatFormEngine.submitForm<K>(
        validateForm: validateForm,
        updateSubmissionStatus: updateSubmissionStatus,
        getFields: () => fields,
        observer: observer,
        onSubmit: onSubmit,
        onError: onError,
        keys: keys,
      );

  /// Resets a field back to its initial value.
  void resetField<T>(K key) => _NeatFormEngine.resetField<T, K>(
        asyncTokens: _asyncValidationTokens,
        fields: fields,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
      );

  /// Resets all fields back to their initial values.
  void resetForm() => _NeatFormEngine.resetForm<K>(
        asyncTokens: _asyncValidationTokens,
        updateSubmissionStatus: updateSubmissionStatus,
        fields: fields,
        updateFields: updateStateWithFields,
        observer: observer,
      );

  /// Clears all errors on all fields without modifying their values.
  void clearErrors() => _NeatFormEngine.clearErrors<K>(
        fields: fields,
        updateFields: updateStateWithFields,
      );
}

/// A mixin for **Riverpod** (`Notifier<S>`) managing a custom or **Freezed** Screen State [S]
/// that contains a nested [NeatFormState<K>].
///
/// ```dart
/// @freezed
/// class LoginScreenState with _$LoginScreenState {
///   const factory LoginScreenState({
///     @Default(false) bool isSubmitting,
///     required NeatFormState<LoginFormKey> form,
///   }) = _LoginScreenState;
/// }
///
/// class LoginNotifier extends Notifier<LoginScreenState>
///     with NeatNestedFormNotifierMixin<LoginScreenState, LoginFormKey> {
///   @override
///   NeatFormState<LoginFormKey> getForm(LoginScreenState state) => state.form;
///
///   @override
///   LoginScreenState updateForm(LoginScreenState state, NeatFormState<LoginFormKey> form) =>
///       state.copyWith(form: form);
///
///   @override
///   Map<LoginFormKey, NeatValidator<Object?>> get validators => { ... };
/// }
/// ```
mixin NeatNestedFormNotifierMixin<S, K> {
  final Map<K, int> _asyncValidationTokens = {};

  /// The current Screen State [S] (e.g. Riverpod `state`).
  S get state;

  /// Setter to update the Screen State [S] (e.g. Riverpod `state = ...`).
  set state(S value);

  /// Extracts the nested [NeatFormState<K>] from the parent state [S].
  NeatFormState<K> getForm(S state);

  /// Returns a copy of [state] with the nested [form] updated.
  S updateForm(S state, NeatFormState<K> form);

  /// Optional observer for event tracking, analytics, or logging.
  NeatFormObserver<K>? get observer => null;

  /// The current map of fields in the nested form state.
  Map<K, NeatFieldState<Object?>> get fields => getForm(state).fields;

  /// The current submission status (idle, submitting, success, failure).
  NeatSubmissionStatus get submissionStatus => getForm(state).status;

  /// The map of validators configured for this form.
  @protected
  Map<K, NeatValidator<Object?>> get validators;

  /// Updates the submission status in the nested form.
  @protected
  void updateSubmissionStatus(NeatSubmissionStatus status) {
    final currentForm = getForm(state);
    if (currentForm.status == status) return;
    state = updateForm(state, currentForm.copyWith(status: status));
    observer?.onSubmissionStatusChanged(status);
  }

  /// Updates field states in the nested form.
  @protected
  void updateStateWithFields(Map<K, NeatFieldState<Object?>> newFields) {
    final currentForm = getForm(state);
    state = updateForm(state, currentForm.copyWith(fields: newFields));
  }

  /// Retrieves a field state by key with strict type safety.
  NeatFieldState<T> getField<T>(K key) =>
      _NeatFormEngine.getField<T, K>(fields, key);

  /// Updates a field's value, optionally clears error, and flags touch.
  void setField<T>(
    K key,
    T value, {
    bool touch = true,
    bool clearError = true,
  }) =>
      _NeatFormEngine.setField<T, K>(
        fields: fields,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
        value: value,
        touch: touch,
        clearError: clearError,
      );

  /// Transforms a field using a custom updater function.
  void updateField<T>(
    K key,
    NeatFieldState<T> Function(NeatFieldState<T> current) updater,
  ) =>
      _NeatFormEngine.updateField<T, K>(
        fields: fields,
        updateFields: updateStateWithFields,
        key: key,
        updater: updater,
      );

  /// Sets a field's value and executes validation immediately.
  NeatValidationError? setAndValidateField<T>(
    K key,
    T value, {
    NeatValidator<T>? validator,
    bool touch = true,
  }) =>
      _NeatFormEngine.setAndValidateField<T, K>(
        fields: fields,
        validators: validators,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
        value: value,
        validator: validator,
        touch: touch,
      );

  /// Runs validation on an existing field value and updates its error state.
  NeatValidationError? validateField<T>(
    K key, {
    NeatValidator<T>? validator,
  }) =>
      _NeatFormEngine.validateField<T, K>(
        fields: fields,
        validators: validators,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
        validator: validator,
      );

  /// Validates an asynchronous rule (e.g. API availability check).
  Future<NeatValidationError?> validateFieldAsync<T>(
    K key,
    NeatAsyncValidator<T> asyncValidator,
  ) =>
      _NeatFormEngine.validateFieldAsync<T, K>(
        asyncTokens: _asyncValidationTokens,
        fields: fields,
        updateField: updateField,
        observer: observer,
        key: key,
        asyncValidator: asyncValidator,
      );

  /// Validates all fields (or a subset of [keys]).
  bool validateForm([List<K>? keys]) => _NeatFormEngine.validateForm<K>(
        fields: fields,
        validators: validators,
        updateFields: updateStateWithFields,
        observer: observer,
        keys: keys,
      );

  /// Submits the form by validating fields and running [onSubmit] if valid.
  Future<bool> submitForm({
    required Future<void> Function(Map<K, Object?> values) onSubmit,
    void Function(Map<K, NeatValidationError> errors)? onError,
    List<K>? keys,
  }) =>
      _NeatFormEngine.submitForm<K>(
        validateForm: validateForm,
        updateSubmissionStatus: updateSubmissionStatus,
        getFields: () => fields,
        observer: observer,
        onSubmit: onSubmit,
        onError: onError,
        keys: keys,
      );

  /// Resets a field back to its initial value.
  void resetField<T>(K key) => _NeatFormEngine.resetField<T, K>(
        asyncTokens: _asyncValidationTokens,
        fields: fields,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
      );

  /// Resets all fields back to their initial values.
  void resetForm() => _NeatFormEngine.resetForm<K>(
        asyncTokens: _asyncValidationTokens,
        updateSubmissionStatus: updateSubmissionStatus,
        fields: fields,
        updateFields: updateStateWithFields,
        observer: observer,
      );

  /// Clears all errors on all fields without modifying their values.
  void clearErrors() => _NeatFormEngine.clearErrors<K>(
        fields: fields,
        updateFields: updateStateWithFields,
      );
}

/// A standalone mixin for **BLoC / Cubit** (`Cubit<NeatFormState<K>>`) managing a standalone [NeatFormState<K>].
///
/// Automatically bridges `state` getter and `emit()` method without requiring manual state mapping.
///
/// ```dart
/// class LoginCubit extends Cubit<NeatFormState<LoginFormKey>>
///     with NeatFormCubitMixin<LoginFormKey> {
///   LoginCubit() : super(NeatFormState.fromValues({
///     LoginFormKey.email: '',
///     LoginFormKey.password: '',
///   }));
///
///   @override
///   Map<LoginFormKey, NeatValidator<Object?>> get validators => { ... };
/// }
/// ```
mixin NeatFormCubitMixin<K> {
  final Map<K, int> _asyncValidationTokens = {};

  /// The current state of the Cubit.
  NeatFormState<K> get state;

  /// The emit method provided by Cubit / BlocBase.
  void emit(NeatFormState<K> state);

  /// Optional observer for event tracking, analytics, or logging.
  NeatFormObserver<K>? get observer => null;

  /// The current map of fields in the form state.
  Map<K, NeatFieldState<Object?>> get fields => state.fields;

  /// The current submission status (idle, submitting, success, failure).
  NeatSubmissionStatus get submissionStatus => state.status;

  /// The map of validators configured for this form.
  @protected
  Map<K, NeatValidator<Object?>> get validators;

  /// Updates the submission status in the Cubit state.
  @protected
  void updateSubmissionStatus(NeatSubmissionStatus status) {
    if (state.status == status) return;
    emit(state.copyWith(status: status));
    observer?.onSubmissionStatusChanged(status);
  }

  /// Updates field states in the Cubit state.
  @protected
  void updateStateWithFields(Map<K, NeatFieldState<Object?>> newFields) {
    emit(state.copyWith(fields: newFields));
  }

  /// Retrieves a field state by key with strict type safety.
  NeatFieldState<T> getField<T>(K key) =>
      _NeatFormEngine.getField<T, K>(fields, key);

  /// Updates a field's value, optionally clears error, and flags touch.
  void setField<T>(
    K key,
    T value, {
    bool touch = true,
    bool clearError = true,
  }) =>
      _NeatFormEngine.setField<T, K>(
        fields: fields,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
        value: value,
        touch: touch,
        clearError: clearError,
      );

  /// Transforms a field using a custom updater function.
  void updateField<T>(
    K key,
    NeatFieldState<T> Function(NeatFieldState<T> current) updater,
  ) =>
      _NeatFormEngine.updateField<T, K>(
        fields: fields,
        updateFields: updateStateWithFields,
        key: key,
        updater: updater,
      );

  /// Sets a field's value and executes validation immediately.
  NeatValidationError? setAndValidateField<T>(
    K key,
    T value, {
    NeatValidator<T>? validator,
    bool touch = true,
  }) =>
      _NeatFormEngine.setAndValidateField<T, K>(
        fields: fields,
        validators: validators,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
        value: value,
        validator: validator,
        touch: touch,
      );

  /// Runs validation on an existing field value and updates its error state.
  NeatValidationError? validateField<T>(
    K key, {
    NeatValidator<T>? validator,
  }) =>
      _NeatFormEngine.validateField<T, K>(
        fields: fields,
        validators: validators,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
        validator: validator,
      );

  /// Validates an asynchronous rule (e.g. API availability check).
  Future<NeatValidationError?> validateFieldAsync<T>(
    K key,
    NeatAsyncValidator<T> asyncValidator,
  ) =>
      _NeatFormEngine.validateFieldAsync<T, K>(
        asyncTokens: _asyncValidationTokens,
        fields: fields,
        updateField: updateField,
        observer: observer,
        key: key,
        asyncValidator: asyncValidator,
      );

  /// Validates all fields (or a subset of [keys]).
  bool validateForm([List<K>? keys]) => _NeatFormEngine.validateForm<K>(
        fields: fields,
        validators: validators,
        updateFields: updateStateWithFields,
        observer: observer,
        keys: keys,
      );

  /// Submits the form by validating fields and running [onSubmit] if valid.
  Future<bool> submitForm({
    required Future<void> Function(Map<K, Object?> values) onSubmit,
    void Function(Map<K, NeatValidationError> errors)? onError,
    List<K>? keys,
  }) =>
      _NeatFormEngine.submitForm<K>(
        validateForm: validateForm,
        updateSubmissionStatus: updateSubmissionStatus,
        getFields: () => fields,
        observer: observer,
        onSubmit: onSubmit,
        onError: onError,
        keys: keys,
      );

  /// Resets a field back to its initial value.
  void resetField<T>(K key) => _NeatFormEngine.resetField<T, K>(
        asyncTokens: _asyncValidationTokens,
        fields: fields,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
      );

  /// Resets all fields back to their initial values.
  void resetForm() => _NeatFormEngine.resetForm<K>(
        asyncTokens: _asyncValidationTokens,
        updateSubmissionStatus: updateSubmissionStatus,
        fields: fields,
        updateFields: updateStateWithFields,
        observer: observer,
      );

  /// Clears all errors on all fields without modifying their values.
  void clearErrors() => _NeatFormEngine.clearErrors<K>(
        fields: fields,
        updateFields: updateStateWithFields,
      );
}

/// A mixin for **BLoC / Cubit** (`Cubit<S>`) managing a custom or **Freezed** Screen State [S]
/// that contains a nested [NeatFormState<K>].
///
/// ```dart
/// class LoginCubit extends Cubit<LoginScreenState>
///     with NeatNestedFormCubitMixin<LoginScreenState, LoginFormKey> {
///   LoginCubit() : super(LoginScreenState(form: NeatFormState.fromValues({ ... })));
///
///   @override
///   NeatFormState<LoginFormKey> getForm(LoginScreenState state) => state.form;
///
///   @override
///   LoginScreenState updateForm(LoginScreenState state, NeatFormState<LoginFormKey> form) =>
///       state.copyWith(form: form);
///
///   @override
///   Map<LoginFormKey, NeatValidator<Object?>> get validators => { ... };
/// }
/// ```
mixin NeatNestedFormCubitMixin<S, K> {
  final Map<K, int> _asyncValidationTokens = {};

  /// The current Screen State [S] of the Cubit.
  S get state;

  /// The emit method provided by Cubit / BlocBase.
  void emit(S state);

  /// Extracts the nested [NeatFormState<K>] from the parent state [S].
  NeatFormState<K> getForm(S state);

  /// Returns a copy of [state] with the nested [form] updated.
  S updateForm(S state, NeatFormState<K> form);

  /// Optional observer for event tracking, analytics, or logging.
  NeatFormObserver<K>? get observer => null;

  /// The current map of fields in the nested form state.
  Map<K, NeatFieldState<Object?>> get fields => getForm(state).fields;

  /// The current submission status (idle, submitting, success, failure).
  NeatSubmissionStatus get submissionStatus => getForm(state).status;

  /// The map of validators configured for this form.
  @protected
  Map<K, NeatValidator<Object?>> get validators;

  /// Updates the submission status in the nested form.
  @protected
  void updateSubmissionStatus(NeatSubmissionStatus status) {
    final currentForm = getForm(state);
    if (currentForm.status == status) return;
    emit(updateForm(state, currentForm.copyWith(status: status)));
    observer?.onSubmissionStatusChanged(status);
  }

  /// Updates field states in the nested form.
  @protected
  void updateStateWithFields(Map<K, NeatFieldState<Object?>> newFields) {
    final currentForm = getForm(state);
    emit(updateForm(state, currentForm.copyWith(fields: newFields)));
  }

  /// Retrieves a field state by key with strict type safety.
  NeatFieldState<T> getField<T>(K key) =>
      _NeatFormEngine.getField<T, K>(fields, key);

  /// Updates a field's value, optionally clears error, and flags touch.
  void setField<T>(
    K key,
    T value, {
    bool touch = true,
    bool clearError = true,
  }) =>
      _NeatFormEngine.setField<T, K>(
        fields: fields,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
        value: value,
        touch: touch,
        clearError: clearError,
      );

  /// Transforms a field using a custom updater function.
  void updateField<T>(
    K key,
    NeatFieldState<T> Function(NeatFieldState<T> current) updater,
  ) =>
      _NeatFormEngine.updateField<T, K>(
        fields: fields,
        updateFields: updateStateWithFields,
        key: key,
        updater: updater,
      );

  /// Sets a field's value and executes validation immediately.
  NeatValidationError? setAndValidateField<T>(
    K key,
    T value, {
    NeatValidator<T>? validator,
    bool touch = true,
  }) =>
      _NeatFormEngine.setAndValidateField<T, K>(
        fields: fields,
        validators: validators,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
        value: value,
        validator: validator,
        touch: touch,
      );

  /// Runs validation on an existing field value and updates its error state.
  NeatValidationError? validateField<T>(
    K key, {
    NeatValidator<T>? validator,
  }) =>
      _NeatFormEngine.validateField<T, K>(
        fields: fields,
        validators: validators,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
        validator: validator,
      );

  /// Validates an asynchronous rule (e.g. API availability check).
  Future<NeatValidationError?> validateFieldAsync<T>(
    K key,
    NeatAsyncValidator<T> asyncValidator,
  ) =>
      _NeatFormEngine.validateFieldAsync<T, K>(
        asyncTokens: _asyncValidationTokens,
        fields: fields,
        updateField: updateField,
        observer: observer,
        key: key,
        asyncValidator: asyncValidator,
      );

  /// Validates all fields (or a subset of [keys]).
  bool validateForm([List<K>? keys]) => _NeatFormEngine.validateForm<K>(
        fields: fields,
        validators: validators,
        updateFields: updateStateWithFields,
        observer: observer,
        keys: keys,
      );

  /// Submits the form by validating fields and running [onSubmit] if valid.
  Future<bool> submitForm({
    required Future<void> Function(Map<K, Object?> values) onSubmit,
    void Function(Map<K, NeatValidationError> errors)? onError,
    List<K>? keys,
  }) =>
      _NeatFormEngine.submitForm<K>(
        validateForm: validateForm,
        updateSubmissionStatus: updateSubmissionStatus,
        getFields: () => fields,
        observer: observer,
        onSubmit: onSubmit,
        onError: onError,
        keys: keys,
      );

  /// Resets a field back to its initial value.
  void resetField<T>(K key) => _NeatFormEngine.resetField<T, K>(
        asyncTokens: _asyncValidationTokens,
        fields: fields,
        updateFields: updateStateWithFields,
        observer: observer,
        key: key,
      );

  /// Resets all fields back to their initial values.
  void resetForm() => _NeatFormEngine.resetForm<K>(
        asyncTokens: _asyncValidationTokens,
        updateSubmissionStatus: updateSubmissionStatus,
        fields: fields,
        updateFields: updateStateWithFields,
        observer: observer,
      );

  /// Clears all errors on all fields without modifying their values.
  void clearErrors() => _NeatFormEngine.clearErrors<K>(
        fields: fields,
        updateFields: updateStateWithFields,
      );
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

  /// Creates a form controller from a simple map of initial values.
  factory NeatFormController.fromValues({
    required Map<K, Object?> initialValues,
    Map<K, bool> optionalKeys = const {},
    Map<K, NeatValidator<Object?>> validators = const {},
    NeatFormObserver<K>? observer,
  }) {
    final formState = NeatFormState<K>.fromValues(
      initialValues,
      optionalKeys: optionalKeys,
    );
    return NeatFormController<K>(
      initialFields: formState.fields,
      validators: validators,
      observer: observer,
    );
  }

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

  /// Returns a snapshot [NeatFormState<K>] of the current controller fields.
  NeatFormState<K> get state => NeatFormState<K>(
        fields: _fields,
        status: submissionStatus,
      );

  /// True if all fields in the form are valid.
  bool get isValid => _fields.values.every((f) => f.isValid);

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

  /// True if any field's value has changed from its initial value.
  bool get isDirty {
    return values.any((field) => field.isDirty);
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
