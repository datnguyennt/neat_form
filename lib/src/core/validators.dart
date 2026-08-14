import 'package:neat_form/src/core/validation_error.dart';
import 'package:neat_form/src/core/validator.dart';

/// Predefined standard validators and validator combinators.
class NeatValidators {
  NeatValidators._();

  /// Default Error Codes
  static const String codeRequired = 'required';
  static const String codeEmail = 'email';
  static const String codeMinLength = 'min_length';
  static const String codeMaxLength = 'max_length';
  static const String codeMinValue = 'min_value';
  static const String codeMaxValue = 'max_value';
  static const String codePattern = 'invalid_pattern';
  static const String codeMatch = 'match_mismatch';
  static const String codeNoSpecialChars = 'no_special_chars';
  static const String codeAlphanumericOnly = 'alphanumeric_only';
  static const String codeNoSpaces = 'no_spaces';
  static const String codeNoLeadingTrailingSpaces = 'no_leading_trailing_spaces';
  static const String codeBlacklist = 'blacklisted_word';

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

  /// Validates that the value is not null and not empty.
  /// Works for String, Iterable, Map, and general objects.
  static NeatValidationError? required(
    dynamic value, {
    String code = codeRequired,
    String? message,
  }) {
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
  }

  /// Validates standard email address format.
  static NeatValidator<dynamic> email({
    String code = codeEmail,
    String? message,
    Pattern? customRegex,
  }) {
    final regex = customRegex ??
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    return (dynamic value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (!regex.allMatches(value).isNotEmpty) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates minimum string length.
  static NeatValidator<dynamic> minLength(
    int min, {
    String code = codeMinLength,
    String? message,
  }) {
    return (dynamic value) {
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
  static NeatValidator<dynamic> maxLength(
    int max, {
    String code = codeMaxLength,
    String? message,
  }) {
    return (dynamic value) {
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
  static NeatValidator<dynamic> lengthRange(
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
  static NeatValidator<dynamic> maxValue(
    num max, {
    String code = codeMaxValue,
    String? message,
  }) {
    return (dynamic value) {
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
  static NeatValidator<dynamic> minValue(
    num min, {
    String code = codeMinValue,
    String? message,
  }) {
    return (dynamic value) {
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
  static NeatValidator<dynamic> pattern(
    Pattern regex, {
    String code = codePattern,
    String? message,
    Map<String, dynamic> params = const {},
  }) {
    return (dynamic value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      final match = regex.allMatches(value).isNotEmpty;
      if (!match) {
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
  static NeatValidator<dynamic> noSpecialChars({
    String code = codeNoSpecialChars,
    String? message,
    Pattern? pattern,
  }) {
    final regex = pattern ?? RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    return (dynamic value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (regex.allMatches(value).isNotEmpty) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that string only contains letters and numbers (alphanumeric).
  static NeatValidator<dynamic> alphanumericOnly({
    String code = codeAlphanumericOnly,
    String? message,
  }) {
    final regex = RegExp(r'^[a-zA-Z0-9]+$');
    return (dynamic value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that string contains no space characters.
  static NeatValidator<dynamic> noSpaces({
    String code = codeNoSpaces,
    String? message,
  }) {
    return (dynamic value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (value.contains(' ')) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that string has no leading or trailing whitespace.
  static NeatValidator<dynamic> noLeadingTrailingSpaces({
    String code = codeNoLeadingTrailingSpaces,
    String? message,
  }) {
    return (dynamic value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (value != value.trim()) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that string does not contain any words from a configurable [blacklist].
  static NeatValidator<dynamic> blacklist(
    List<String> words, {
    String code = codeBlacklist,
    bool caseSensitive = false,
    String? message,
  }) {
    return (dynamic value) {
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
    Map<String, dynamic> params = const {},
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
