import 'package:meta/meta.dart';
import 'package:neat_form/src/core/validation_error.dart';

/// Immutable model representing the current state of a form field.
@immutable
class NeatFieldState<T> {
  const NeatFieldState({
    required this.value,
    this.error,
    this.showError = false,
    this.isTouched = false,
    this.isOptional = false,
    this.isValidating = false,
    this.isValidated = false,
    this.initialValue,
  });

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
  bool get isDirty {
    if (initialValue == null) return false;
    return value != initialValue;
  }

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
  bool get isShowError => showError && isInvalid;

  /// True if error is not shown.
  bool get isNotShowError => !isShowError;

  /// Returns a copy of this state with specified fields updated.
  NeatFieldState<T> copyWith({
    T? value,
    NeatValidationError? Function()? error,
    bool? showError,
    bool? isTouched,
    bool? isOptional,
    bool? isValidating,
    bool? isValidated,
    T? Function()? initialValue,
  }) {
    return NeatFieldState<T>(
      value: value ?? this.value,
      error: error != null ? error() : this.error,
      showError: showError ?? this.showError,
      isTouched: isTouched ?? this.isTouched,
      isOptional: isOptional ?? this.isOptional,
      isValidating: isValidating ?? this.isValidating,
      isValidated: isValidated ?? this.isValidated,
      initialValue: initialValue != null ? initialValue() : this.initialValue,
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
      'NeatFieldState(value: $value, error: $error, showError: $showError, isTouched: $isTouched, isOptional: $isOptional)';
}
