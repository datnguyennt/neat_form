import 'package:meta/meta.dart';
import 'package:neat_form/src/form_controller.dart';

const Object _sentinel = Object();

/// Short alias for [NeatFormState].
typedef NeatForm<K> = NeatFormState<K>;

/// Represents the lifecycle status of form submission.
enum NeatSubmissionStatus {
  /// Initial idle state before submission.
  idle,

  /// Submission is currently in progress (show loader).
  submitting,

  /// Submission succeeded.
  success,

  /// Submission failed with an error.
  failure;

  /// Whether the status is [idle].
  bool get isIdle => this == NeatSubmissionStatus.idle;

  /// Whether the status is [submitting].
  bool get isSubmitting => this == NeatSubmissionStatus.submitting;

  /// Whether the status is [success].
  bool get isSuccess => this == NeatSubmissionStatus.success;

  /// Whether the status is [failure].
  bool get isFailure => this == NeatSubmissionStatus.failure;
}

/// Represents a validation error with a machine-readable [code] and optional [params].
@immutable
class NeatValidationError {
  /// Creates a validation error with a [code], optional [params], and fallback [message].
  const NeatValidationError(
    this.code, {
    this.params = const {},
    this.message,
  });

  /// Convenience factory for simple error codes without parameters.
  const NeatValidationError.code(this.code)
      : params = const {},
        message = null;

  /// Unique error identifier code (e.g. 'required', 'min_length', 'invalid_email').
  final String code;

  /// Additional parameters for error message interpolation (e.g. `{'minLength': 8}`).
  final Map<String, Object?> params;

  /// Custom fallback message if needed.
  final String? message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NeatValidationError &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message &&
          _mapsEqual(params, other.params);

  @override
  int get hashCode {
    final sortedEntries = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Object.hash(
      code,
      message,
      Object.hashAll(
        sortedEntries.map((e) => Object.hash(e.key, _elementHash(e.value))),
      ),
    );
  }

  static int _elementHash(Object? element) {
    if (element is Map) {
      final sorted = element.entries.toList()
        ..sort((a, b) => '${a.key}'.compareTo('${b.key}'));
      return Object.hashAll(
        sorted.map((e) => Object.hash(e.key, _elementHash(e.value))),
      );
    }
    if (element is Iterable) {
      return Object.hashAll(element.map(_elementHash));
    }
    return element.hashCode;
  }

  static bool _mapsEqual(Map<String, Object?> a, Map<String, Object?> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }

  static bool _deepEquals(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is Iterable && b is Iterable) {
      if (a.length != b.length) return false;
      final iterA = a.iterator;
      final iterB = b.iterator;
      while (iterA.moveNext() && iterB.moveNext()) {
        if (!_deepEquals(iterA.current, iterB.current)) return false;
      }
      return true;
    }
    return a == b;
  }

  @override
  String toString() =>
      'NeatValidationError(code: $code, params: $params, message: $message)';
}

/// Immutable model representing the current state of a form field.
@immutable
class NeatFieldState<T> {
  /// Creates a state container for a single form field.
  const NeatFieldState({
    required this.value,
    this.error,
    this.showError = false,
    this.isTouched = false,
    this.isOptional = false,
    this.isValidating = false,
    this.isValidated = false,
    Object? initialValue = _sentinel,
  }) : initialValue = identical(initialValue, _sentinel)
            ? value
            : initialValue as T?;

  /// The current value of the field.
  final T value;

  /// Current validation error, or `null` if valid.
  final NeatValidationError? error;

  /// Whether the error should be displayed in the UI.
  final bool showError;

  /// Whether the user has interacted (touched / blurred) with this field.
  final bool isTouched;

  /// Whether this field is optional (empty values bypass required checks).
  final bool isOptional;

  /// Whether an asynchronous validation is currently running.
  final bool isValidating;

  /// Whether validation has run at least once on this field.
  final bool isValidated;

  /// The initial value of the field for tracking dirty state.
  final T? initialValue;

  /// True if there is no validation error.
  bool get isValid => error == null;

  /// True if there is a validation error.
  bool get isInvalid => !isValid;

  /// True if the current value differs from [initialValue].
  bool get isDirty => value != initialValue;

  /// Checks if value is empty across common Dart types (null, String, Iterable, Map).
  bool get isEmpty {
    final v = value;
    if (v == null) return true;
    if (v is String) return v.trim().isEmpty;
    if (v is Iterable) return v.isEmpty;
    if (v is Map) return v.isEmpty;
    return false;
  }

  /// True if value is not empty.
  bool get isNotEmpty => !isEmpty;

  /// True if error exists and is flagged to be shown in UI.
  bool get isErrorVisible => showError && isInvalid;

  /// Backward compatible alias for [isErrorVisible].
  bool get isShowError => isErrorVisible;

  /// Directly returns [NeatValidationError.message] if [isErrorVisible] is true, otherwise `null`.
  ///
  /// Perfect for binding directly to Flutter's `InputDecoration.errorText`:
  /// ```dart
  /// InputDecoration(
  ///   errorText: field.errorMessage,
  /// )
  /// ```
  String? get errorMessage => isErrorVisible ? error?.message : null;

  /// Returns a copy of this state with specified fields updated.
  NeatFieldState<T> copyWith({
    Object? value = _sentinel,
    Object? error = _sentinel,
    bool? showError,
    bool? isTouched,
    bool? isOptional,
    bool? isValidating,
    bool? isValidated,
    Object? initialValue = _sentinel,
  }) {
    return NeatFieldState<T>(
      value: identical(value, _sentinel) ? this.value : value as T,
      error: identical(error, _sentinel)
          ? this.error
          : error as NeatValidationError?,
      showError: showError ?? this.showError,
      isTouched: isTouched ?? this.isTouched,
      isOptional: isOptional ?? this.isOptional,
      isValidating: isValidating ?? this.isValidating,
      isValidated: isValidated ?? this.isValidated,
      initialValue: identical(initialValue, _sentinel)
          ? this.initialValue
          : initialValue as T?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NeatFieldState<T> &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          error == other.error &&
          showError == other.showError &&
          isTouched == other.isTouched &&
          isOptional == other.isOptional &&
          isValidating == other.isValidating &&
          isValidated == other.isValidated &&
          initialValue == other.initialValue;

  @override
  int get hashCode => Object.hash(
        value,
        error,
        showError,
        isTouched,
        isOptional,
        isValidating,
        isValidated,
        initialValue,
      );

  @override
  String toString() =>
      'NeatFieldState(value: $value, error: $error, isErrorVisible: $isErrorVisible, '
      'isTouched: $isTouched, isOptional: $isOptional, isDirty: $isDirty)';
}

/// An immutable container encapsulating all form field states and submission lifecycle status.
///
/// Specially tailored for **Riverpod** (`Notifier<NeatFormState<K>>`) and **BLoC/Cubit**
/// (`Cubit<NeatFormState<K>>`) to eliminate custom State class boilerplate.
@immutable
class NeatFormState<K> {
  /// Creates an immutable form state with [fields] and optional submission [status].
  const NeatFormState({
    this.fields = const {},
    this.status = NeatSubmissionStatus.idle,
  });

  /// Factory constructor to effortlessly initialize a [NeatFormState] from raw key-value pairs.
  ///
  /// ```dart
  /// NeatFormState.fromValues({
  ///   LoginFormKey.email: '',
  ///   LoginFormKey.password: '',
  ///   LoginFormKey.age: 18,
  /// })
  /// ```
  factory NeatFormState.fromValues(
    Map<K, Object?> rawValues, {
    Map<K, bool> optionalKeys = const {},
    NeatSubmissionStatus status = NeatSubmissionStatus.idle,
  }) {
    final fields = rawValues.map(
      (key, value) => MapEntry(
        key,
        NeatFieldState<Object?>(
          value: value,
          isOptional: optionalKeys[key] ?? false,
        ),
      ),
    );
    return NeatFormState<K>(fields: fields, status: status);
  }

  /// Map containing all field states keyed by [K].
  final Map<K, NeatFieldState<Object?>> fields;

  /// Current form submission lifecycle status.
  final NeatSubmissionStatus status;

  /// Alias for [status].
  NeatSubmissionStatus get submissionStatus => status;

  /// Type-safe retrieval of a field state.
  NeatFieldState<T> getField<T>(K key) => fields.getField<T>(key);

  /// Concise alias for [getField].
  NeatFieldState<T> field<T>(K key) => fields.getField<T>(key);

  /// Index operator to access field state directly: `state[key]`.
  NeatFieldState<Object?> operator [](K key) => fields.getField<Object?>(key);

  /// Raw value of a field, or `null` if not found or null.
  T? valueOf<T>(K key) => fields.valueOf<T>(key);

  /// Current validation error of a field, or `null` if valid.
  NeatValidationError? errorOf(K key) => fields.errorOf(key);

  /// Returns `true` if all fields are valid and non-empty (or valid optional).
  bool get isValid => fields.areAllFieldsValid;

  /// Returns `true` if all fields are free of validation errors.
  bool get isCleanAndValid => fields.isCleanAndValid;

  /// Returns `true` if any field in the form has been modified from its initial value.
  bool get isDirty => fields.isDirty;

  /// Returns `true` if any field in the form has been touched/interacted with.
  bool get isTouched => fields.values.any((f) => f.isTouched);

  /// Returns `true` if any field is currently undergoing async validation.
  bool get isValidating => fields.values.any((f) => f.isValidating);

  /// Whether submission is currently in progress.
  bool get isSubmitting => status.isSubmitting;

  /// Whether the last submission attempt succeeded.
  bool get isSuccess => status.isSuccess;

  /// Whether the last submission attempt failed.
  bool get isFailure => status.isFailure;

  /// Exports all field keys and their current values as a raw Map.
  Map<K, Object?> get values => fields.toValuesMap();

  /// Returns a copy of this form state with updated fields or status.
  NeatFormState<K> copyWith({
    Map<K, NeatFieldState<Object?>>? fields,
    NeatSubmissionStatus? status,
  }) {
    return NeatFormState<K>(
      fields: fields ?? this.fields,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NeatFormState<K> &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          _fieldsEqual(fields, other.fields);

  @override
  int get hashCode {
    var fieldsHash = 0;
    for (final entry in fields.entries) {
      fieldsHash ^= Object.hash(entry.key, entry.value);
    }
    return Object.hash(fieldsHash, status);
  }

  static bool _fieldsEqual<K>(
    Map<K, NeatFieldState<Object?>> a,
    Map<K, NeatFieldState<Object?>> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'NeatFormState(status: $status, fields: ${fields.length}, isValid: $isValid, isDirty: $isDirty)';
}
