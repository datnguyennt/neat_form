import 'package:meta/meta.dart';

const Object _sentinel = Object();

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
