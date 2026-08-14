import 'package:meta/meta.dart';

/// Represents a validation error with a machine-readable [code] and optional [params].
///
/// This class is pure Dart and has no dependencies on Flutter UI or BuildContext,
/// enabling clean separation between form business logic and UI localization.
@immutable
class NeatValidationError {
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
  final Map<String, dynamic> params;

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
  int get hashCode => Object.hash(
        code,
        message,
        Object.hashAll(params.entries.map((e) => Object.hash(e.key, e.value))),
      );

  static bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'NeatValidationError(code: $code, params: $params, message: $message)';
}
