import 'package:neat_form/src/field_state.dart';

/// A synchronous validator function that inspects a value of type [T]
/// and returns a [NeatValidationError] if invalid, or `null` if valid.
typedef NeatValidator<T> = NeatValidationError? Function(T? value);

/// An asynchronous validator function that inspects a value of type [T]
/// and returns a [Future] containing [NeatValidationError] if invalid, or `null` if valid.
typedef NeatAsyncValidator<T> = Future<NeatValidationError?> Function(T? value);

/// Signature for a function that resolves a localized error string from a [NeatValidationError].
typedef NeatErrorStringResolver<Context> = String Function(
  Context context,
  NeatValidationError error, {
  String? fieldName,
});

/// Predefined standard validators and validator combinators.
class NeatValidators {
  NeatValidators._();

  /// Default Error Code for required fields.
  static const String codeRequired = 'required';

  /// Default Error Code for email validation failure.
  static const String codeEmail = 'email';

  /// Default Error Code for minimum string length violation.
  static const String codeMinLength = 'min_length';

  /// Default Error Code for maximum string length violation.
  static const String codeMaxLength = 'max_length';

  /// Default Error Code for minimum numeric value violation.
  static const String codeMinValue = 'min_value';

  /// Default Error Code for maximum numeric value violation.
  static const String codeMaxValue = 'max_value';

  /// Default Error Code for regular expression pattern mismatch.
  static const String codePattern = 'invalid_pattern';

  /// Default Error Code for field equality mismatch.
  static const String codeMatch = 'match_mismatch';

  /// Default Error Code for special characters violation.
  static const String codeNoSpecialChars = 'no_special_chars';

  /// Default Error Code for alphanumeric-only violation.
  static const String codeAlphanumericOnly = 'alphanumeric_only';

  /// Default Error Code for whitespace presence violation.
  static const String codeNoSpaces = 'no_spaces';

  /// Default Error Code for leading or trailing whitespace.
  static const String codeNoLeadingTrailingSpaces =
      'no_leading_trailing_spaces';

  /// Default Error Code for blacklisted words.
  static const String codeBlacklist = 'blacklisted_word';

  /// Default Error Code for non-numeric input.
  static const String codeNumeric = 'numeric';

  /// Default Error Code for invalid URL.
  static const String codeUrl = 'invalid_url';

  static final RegExp _emailRegExp =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp _defaultSpecialCharsRegExp =
      RegExp(r'[!@#$%^&*(),.?":{}|<>]');
  static final RegExp _alphanumericRegExp = RegExp(r'^[a-zA-Z0-9]+$');

  /// Combines multiple validators into one. Evaluates in order, stops at the first error.
  static NeatValidator<T> combine<T>(List<NeatValidator<T>> validators) {
    return (T? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Conditionally runs a [validator] only when [condition] evaluates to `true`.
  static NeatValidator<T> when<T>(
    bool Function() condition,
    NeatValidator<T> validator,
  ) {
    return (T? value) {
      if (!condition()) return null;
      return validator(value);
    };
  }

  /// Factory that returns a required validator.
  ///
  /// ```dart
  /// NeatValidators.required(message: 'Please fill in this field')
  /// ```
  static NeatValidator<T> required<T>({
    String code = codeRequired,
    String? message,
  }) {
    return (T? value) {
      if (value == null) {
        return NeatValidationError(code, message: message);
      }
      if (value is String && value.trim().isEmpty) {
        return NeatValidationError(code, message: message);
      }
      if (value is Iterable && value.isEmpty) {
        return NeatValidationError(code, message: message);
      }
      if (value is Map && value.isEmpty) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Backward-compatible alias for [required].
  static NeatValidator<T> requiredWith<T>({
    String code = codeRequired,
    String? message,
  }) =>
      required<T>(code: code, message: message);

  /// Validates standard email address format.
  static NeatValidator<Object?> email({
    String code = codeEmail,
    String? message,
    Pattern? customRegex,
  }) {
    final regex = customRegex ?? _emailRegExp;

    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      final isMatch = regex is RegExp
          ? regex.hasMatch(value)
          : regex.allMatches(value).isNotEmpty;
      if (!isMatch) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates minimum string length.
  static NeatValidator<Object?> minLength(
    int min, {
    String code = codeMinLength,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (value.length < min) {
        return NeatValidationError(
          code,
          params: {'minLength': min, 'count': min},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates maximum string length.
  static NeatValidator<Object?> maxLength(
    int max, {
    String code = codeMaxLength,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (value.length > max) {
        return NeatValidationError(
          code,
          params: {'maxLength': max, 'count': max},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates string length is within [min] and [max].
  static NeatValidator<Object?> lengthRange(
    int min,
    int max, {
    String? minCode,
    String? maxCode,
  }) {
    return combine([
      minLength(min, code: minCode ?? codeMinLength),
      maxLength(max, code: maxCode ?? codeMaxLength),
    ]);
  }

  /// Validates numeric maximum value.
  static NeatValidator<Object?> maxValue(
    num max, {
    String code = codeMaxValue,
    String? message,
  }) {
    return (Object? value) {
      if (value is! num?) return null;
      if (value == null) return null;
      if (value > max) {
        return NeatValidationError(
          code,
          params: {'maxValue': max, 'value': max},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates numeric minimum value.
  static NeatValidator<Object?> minValue(
    num min, {
    String code = codeMinValue,
    String? message,
  }) {
    return (Object? value) {
      if (value is! num?) return null;
      if (value == null) return null;
      if (value < min) {
        return NeatValidationError(
          code,
          params: {'minValue': min, 'value': min},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates that value matches a regular expression pattern.
  static NeatValidator<Object?> pattern(
    Pattern regex, {
    String code = codePattern,
    String? message,
    Map<String, Object?> params = const {},
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      final isMatch = regex is RegExp
          ? regex.hasMatch(value)
          : regex.allMatches(value).isNotEmpty;
      if (!isMatch) {
        return NeatValidationError(code, params: params, message: message);
      }
      return null;
    };
  }

  /// Validates that value matches another target value (e.g. Confirm Password).
  /// Uses a getter callback [targetValueGetter] to dynamically resolve the current target value.
  static NeatValidator<T> match<T>(
    T? Function() targetValueGetter, {
    String code = codeMatch,
    String? message,
  }) {
    return (T? value) {
      if (value == null) return null;
      final target = targetValueGetter();
      if (value != target) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that string has no special characters.
  static NeatValidator<Object?> noSpecialChars({
    String code = codeNoSpecialChars,
    String? message,
    Pattern? pattern,
  }) {
    final regex = pattern ?? _defaultSpecialCharsRegExp;
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      final hasSpecial = regex is RegExp
          ? regex.hasMatch(value)
          : regex.allMatches(value).isNotEmpty;
      if (hasSpecial) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that string only contains letters and numbers (alphanumeric).
  static NeatValidator<Object?> alphanumericOnly({
    String code = codeAlphanumericOnly,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (!_alphanumericRegExp.hasMatch(value)) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that string contains a valid numeric value (integer or decimal).
  static NeatValidator<Object?> numeric({
    String code = codeNumeric,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (num.tryParse(value) == null) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that string is a valid URL with allowed schemes.
  static NeatValidator<Object?> url({
    String code = codeUrl,
    String? message,
    List<String> allowedSchemes = const ['http', 'https'],
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      final uri = Uri.tryParse(value);
      if (uri == null ||
          !uri.hasScheme ||
          !allowedSchemes.contains(uri.scheme) ||
          uri.host.isEmpty) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that string contains no space characters.
  static NeatValidator<Object?> noSpaces({
    String code = codeNoSpaces,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (value.contains(' ')) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that string has no leading or trailing whitespace.
  static NeatValidator<Object?> noLeadingTrailingSpaces({
    String code = codeNoLeadingTrailingSpaces,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (value != value.trim()) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that string does not contain any words from a configurable [blacklist].
  static NeatValidator<Object?> blacklist(
    List<String> words, {
    String code = codeBlacklist,
    bool caseSensitive = false,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      final target = caseSensitive ? value : value.toLowerCase();
      for (final word in words) {
        final query = caseSensitive ? word : word.toLowerCase();
        if (target.contains(query)) {
          return NeatValidationError(
            code,
            params: {'word': word},
            message: message,
          );
        }
      }
      return null;
    };
  }

  /// Creates a custom validator from a predicate function.
  static NeatValidator<T> custom<T>(
    bool Function(T? value) isValid, {
    required String code,
    Map<String, Object?> params = const {},
    String? message,
  }) {
    return (T? value) {
      if (!isValid(value)) {
        return NeatValidationError(code, params: params, message: message);
      }
      return null;
    };
  }
}

/// A configurable resolver registry that maps error codes to localized strings or templates.
class NeatErrorResolver<Context> {
  /// Creates an error resolver with an optional fallback resolver.
  NeatErrorResolver({
    this.fallbackResolver,
  });

  final Map<
          String,
          String Function(
            Context context,
            Map<String, Object?> params,
            String? fieldName,
          )>
      _resolvers = {};

  /// Global fallback resolver for unhandled error codes.
  NeatErrorStringResolver<Context>? fallbackResolver;

  /// Registers a handler for a specific error code.
  void register(
    String code,
    String Function(
      Context context,
      Map<String, Object?> params,
      String? fieldName,
    ) handler,
  ) {
    _resolvers[code] = handler;
  }

  /// Resolves an error into a human-readable string.
  ///
  /// If a registered handler is found for `error.code`, it is used.
  /// Otherwise, if a fallback resolver is set, it is invoked.
  /// Otherwise, falls back to `error.message` or `error.code`, interpolating any `{key}` tokens from `error.params`.
  String resolve(
    Context context,
    NeatValidationError error, {
    String? fieldName,
  }) {
    final handler = _resolvers[error.code];
    if (handler != null) {
      return handler(context, error.params, fieldName);
    }

    final fallback = fallbackResolver;
    if (fallback != null) {
      return fallback(context, error, fieldName: fieldName);
    }

    final rawTemplate = error.message ?? error.code;
    return _interpolate(rawTemplate, error.params);
  }

  /// Replaces `{key}` placeholders in [template] with matching values from [params].
  static String _interpolate(String template, Map<String, Object?> params) {
    if (params.isEmpty) return template;
    var result = template;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', '$value');
    });
    return result;
  }
}
