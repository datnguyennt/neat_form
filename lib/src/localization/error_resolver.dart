import 'package:neat_form/src/core/validation_error.dart';

/// Signature for a function that resolves a localized error string from a [NeatValidationError].
typedef NeatErrorStringResolver<Context> = String Function(
  Context context,
  NeatValidationError error, {
  String? fieldName,
});

/// A configurable resolver registry that maps error codes to localized strings or templates.
class NeatErrorResolver<Context> {
  NeatErrorResolver({
    NeatErrorStringResolver<Context>? fallbackResolver,
  }) : _fallbackResolver = fallbackResolver;

  final Map<String,
          String Function(Context context, Map<String, dynamic> params, String? fieldName)>
      _resolvers = {};

  NeatErrorStringResolver<Context>? _fallbackResolver;

  /// Registers a handler for a specific error code.
  void register(
    String code,
    String Function(Context context, Map<String, dynamic> params, String? fieldName) handler,
  ) {
    _resolvers[code] = handler;
  }

  /// Sets a global fallback resolver for unhandled error codes.
  void setFallback(NeatErrorStringResolver<Context> fallback) {
    _fallbackResolver = fallback;
  }

  /// Resolves an error into a human-readable string.
  String resolve(
    Context context,
    NeatValidationError error, {
    String? fieldName,
  }) {
    final handler = _resolvers[error.code];
    if (handler != null) {
      return handler(context, error.params, fieldName);
    }

    if (_fallbackResolver != null) {
      return _fallbackResolver!(context, error, fieldName: fieldName);
    }

    return error.message ?? error.code;
  }
}
