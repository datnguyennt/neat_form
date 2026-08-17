import 'dart:convert';

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

  // --- Core Error Codes ---

  /// Default Error Code for required fields.
  static const String codeRequired = 'required';

  /// Default Error Code for blank-only strings.
  static const String codeNotBlank = 'not_blank';

  /// Default Error Code for exact string length violation.
  static const String codeExactLength = 'exact_length';

  /// Default Error Code for email validation failure.
  static const String codeEmail = 'email';

  /// Default Error Code for phone validation failure.
  static const String codePhone = 'phone';

  /// Default Error Code for minimum string length violation.
  static const String codeMinLength = 'min_length';

  /// Default Error Code for maximum string length violation.
  static const String codeMaxLength = 'max_length';

  /// Default Error Code for string prefix violation.
  static const String codeStartsWith = 'starts_with';

  /// Default Error Code for string suffix violation.
  static const String codeEndsWith = 'ends_with';

  /// Default Error Code for substring containment requirement.
  static const String codeContains = 'contains';

  /// Default Error Code for forbidden substring containment.
  static const String codeNotContains = 'not_contains';

  /// Default Error Code for Latin-only character requirement.
  static const String codeLatinOnly = 'latin_only';

  /// Default Error Code for emoji presence violation.
  static const String codeNoEmoji = 'no_emoji';

  /// Default Error Code for minimum numeric value violation.
  static const String codeMinValue = 'min_value';

  /// Default Error Code for maximum numeric value violation.
  static const String codeMaxValue = 'max_value';

  /// Default Error Code for non-positive number violation.
  static const String codePositive = 'positive';

  /// Default Error Code for non-negative number violation.
  static const String codeNegative = 'negative';

  /// Default Error Code for number step / multiple violation.
  static const String codeMultipleOf = 'multiple_of';

  /// Default Error Code for decimal precision violation.
  static const String codeDecimalPrecision = 'decimal_precision';

  /// Default Error Code for regular expression pattern mismatch.
  static const String codePattern = 'invalid_pattern';

  /// Default Error Code for field equality mismatch.
  static const String codeMatch = 'match_mismatch';

  /// Default Error Code for password strength inadequacy.
  static const String codePasswordStrength = 'weak_password';

  /// Default Error Code for invalid credit card numbers (Luhn check).
  static const String codeCreditCard = 'invalid_credit_card';

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

  /// Default Error Code for past date requirement violation.
  static const String codePastDate = 'past_date';

  /// Default Error Code for future date requirement violation.
  static const String codeFutureDate = 'future_date';

  /// Default Error Code for date range violation.
  static const String codeDateRange = 'date_range';

  /// Default Error Code for formatted date string violation.
  static const String codeDateString = 'date_string';

  /// Default Error Code for boolean true requirement violation.
  static const String codeMustBeTrue = 'must_be_true';

  /// Default Error Code for boolean false requirement violation.
  static const String codeMustBeFalse = 'must_be_false';

  /// Default Error Code for collection minimum items violation.
  static const String codeMinItems = 'min_items';

  /// Default Error Code for collection maximum items violation.
  static const String codeMaxItems = 'max_items';

  /// Default Error Code for collection duplicate items violation.
  static const String codeUniqueItems = 'unique_items';

  /// Default Error Code for HTML tags presence violation.
  static const String codeNoHtml = 'no_html';

  /// Default Error Code for non-negative number requirement violation.
  static const String codeNonNegative = 'non_negative';

  /// Default Error Code for non-positive number requirement violation.
  static const String codeNonPositive = 'non_positive';

  /// Default Error Code for value range violation.
  static const String codeValueRange = 'value_range';

  /// Default Error Code for integer-only input violation.
  static const String codeIntegerOnly = 'integer_only';

  /// Default Error Code for value not in allowed set.
  static const String codeOneOf = 'one_of';

  /// Default Error Code for value in forbidden set.
  static const String codeNoneOf = 'none_of';

  /// Default Error Code for expired credit card.
  static const String codeCreditCardExpiry = 'credit_card_expired';

  /// Default Error Code for time string format or range violation.
  static const String codeTimeString = 'time_string';

  /// Default Error Code for invalid IP address.
  static const String codeIp = 'invalid_ip';

  /// Default Error Code for invalid JSON string.
  static const String codeJson = 'invalid_json';

  /// Default Error Code for invalid Hex Color string.
  static const String codeHexColor = 'invalid_hex_color';

  /// Default Error Code for invalid UUID string.
  static const String codeUuid = 'invalid_uuid';

  // --- Regular Expressions ---

  static final RegExp _emailRegExp =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp _phoneRegExp = RegExp(r'^\+?[0-9]{8,15}$');
  static final RegExp _defaultSpecialCharsRegExp =
      RegExp(r'[!@#$%^&*(),.?":{}|<>]');
  static final RegExp _alphanumericRegExp = RegExp(r'^[a-zA-Z0-9]+$');
  static final RegExp _latinOnlyRegExp = RegExp(r'^[a-zA-Z\s]+$');
  static final RegExp _emojiRegExp = RegExp(
    r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F018}-\u{1F270}]',
    unicode: true,
  );
  static final RegExp _htmlTagRegExp = RegExp('<[^>]*>');
  static final RegExp _ipv4RegExp = RegExp(
    r'^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
  );
  static final RegExp _ipv6RegExp = RegExp(
    r'^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$',
  );
  static final RegExp _uuidRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  static final RegExp _uuidAnyVersionRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static final RegExp _hexColorWithHashRegExp = RegExp(
    r'^#([0-9a-fA-F]{3}|[0-9a-fA-F]{4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$',
  );
  static final RegExp _hexColorAnyRegExp = RegExp(
    r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$',
  );

  // --- Combinators ---

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

  // --- String & Format Validators ---

  /// Factory that returns a required validator (non-null, non-empty).
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

  /// Validates that string is not blank (does not consist purely of whitespace).
  static NeatValidator<Object?> notBlank({
    String code = codeNotBlank,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (value.trim().isEmpty) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates exact string length.
  static NeatValidator<Object?> exactLength(
    int length, {
    String code = codeExactLength,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (value.length != length) {
        return NeatValidationError(
          code,
          params: {'length': length, 'count': length},
          message: message,
        );
      }
      return null;
    };
  }

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

  /// Validates phone number format (8-15 digits, optional '+' prefix).
  static NeatValidator<Object?> phone({
    String code = codePhone,
    String? message,
    Pattern? customRegex,
  }) {
    final regex = customRegex ?? _phoneRegExp;
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      final sanitized = value.replaceAll(RegExp(r'[\s\-()]'), '');
      final isMatch = regex is RegExp
          ? regex.hasMatch(sanitized)
          : regex.allMatches(sanitized).isNotEmpty;
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

  /// Validates that string starts with [prefix].
  static NeatValidator<Object?> startsWith(
    String prefix, {
    String code = codeStartsWith,
    String? message,
    bool caseSensitive = true,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      final target = caseSensitive ? value : value.toLowerCase();
      final pre = caseSensitive ? prefix : prefix.toLowerCase();
      if (!target.startsWith(pre)) {
        return NeatValidationError(
          code,
          params: {'prefix': prefix},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates that string ends with [suffix].
  static NeatValidator<Object?> endsWith(
    String suffix, {
    String code = codeEndsWith,
    String? message,
    bool caseSensitive = true,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      final target = caseSensitive ? value : value.toLowerCase();
      final suf = caseSensitive ? suffix : suffix.toLowerCase();
      if (!target.endsWith(suf)) {
        return NeatValidationError(
          code,
          params: {'suffix': suffix},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates that string contains [substring].
  static NeatValidator<Object?> contains(
    String substring, {
    String code = codeContains,
    String? message,
    bool caseSensitive = true,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      final target = caseSensitive ? value : value.toLowerCase();
      final sub = caseSensitive ? substring : substring.toLowerCase();
      if (!target.contains(sub)) {
        return NeatValidationError(
          code,
          params: {'substring': substring},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates that string does NOT contain [substring].
  static NeatValidator<Object?> notContains(
    String substring, {
    String code = codeNotContains,
    String? message,
    bool caseSensitive = true,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      final target = caseSensitive ? value : value.toLowerCase();
      final sub = caseSensitive ? substring : substring.toLowerCase();
      if (target.contains(sub)) {
        return NeatValidationError(
          code,
          params: {'substring': substring},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates that string only contains Latin alphabet characters and whitespace (A-Z, a-z).
  static NeatValidator<Object?> latinOnly({
    String code = codeLatinOnly,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (!_latinOnlyRegExp.hasMatch(value)) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that string contains no Emoji icons.
  static NeatValidator<Object?> noEmoji({
    String code = codeNoEmoji,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (_emojiRegExp.hasMatch(value)) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates password complexity strength.
  static NeatValidator<Object?> passwordStrength({
    int minUppercase = 1,
    int minLowercase = 1,
    int minDigits = 1,
    int minSpecialChars = 1,
    String code = codePasswordStrength,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;

      final upperCount = value.split('').where((c) => c.contains(RegExp('[A-Z]'))).length;
      final lowerCount = value.split('').where((c) => c.contains(RegExp('[a-z]'))).length;
      final digitCount = value.split('').where((c) => c.contains(RegExp('[0-9]'))).length;
      final specialCount = value.split('').where(_defaultSpecialCharsRegExp.hasMatch).length;

      if (upperCount < minUppercase ||
          lowerCount < minLowercase ||
          digitCount < minDigits ||
          specialCount < minSpecialChars) {
        return NeatValidationError(
          code,
          params: {
            'minUppercase': minUppercase,
            'minLowercase': minLowercase,
            'minDigits': minDigits,
            'minSpecialChars': minSpecialChars,
          },
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates credit card numbers using the Luhn Algorithm.
  static NeatValidator<Object?> creditCard({
    String code = codeCreditCard,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;

      final cleanNumber = value.replaceAll(RegExp(r'[\s\-]'), '');
      if (cleanNumber.length < 13 || cleanNumber.length > 19 || int.tryParse(cleanNumber) == null) {
        return NeatValidationError(code, message: message);
      }

      var sum = 0;
      var alternate = false;
      for (var i = cleanNumber.length - 1; i >= 0; i--) {
        var n = int.parse(cleanNumber[i]);
        if (alternate) {
          n *= 2;
          if (n > 9) n = (n % 10) + 1;
        }
        sum += n;
        alternate = !alternate;
      }

      if (sum % 10 != 0) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  // --- Numeric Validators ---

  static num? _tryExtractNum(Object? value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return num.tryParse(trimmed);
    }
    return null;
  }

  /// Validates numeric maximum value (supports `num` and numeric `String`).
  static NeatValidator<Object?> maxValue(
    num max, {
    String code = codeMaxValue,
    String? message,
  }) {
    return (Object? value) {
      if (value == null) return null;
      final numVal = _tryExtractNum(value);
      if (numVal == null) return null;
      if (numVal > max) {
        return NeatValidationError(
          code,
          params: {'maxValue': max, 'value': numVal},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates numeric minimum value (supports `num` and numeric `String`).
  static NeatValidator<Object?> minValue(
    num min, {
    String code = codeMinValue,
    String? message,
  }) {
    return (Object? value) {
      if (value == null) return null;
      final numVal = _tryExtractNum(value);
      if (numVal == null) return null;
      if (numVal < min) {
        return NeatValidationError(
          code,
          params: {'minValue': min, 'value': numVal},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates that numeric value is within [min] and [max] range (inclusive).
  static NeatValidator<Object?> valueRange(
    num min,
    num max, {
    String code = codeValueRange,
    String? message,
  }) {
    return (Object? value) {
      if (value == null) return null;
      final numVal = _tryExtractNum(value);
      if (numVal == null) return null;
      if (numVal < min || numVal > max) {
        return NeatValidationError(
          code,
          params: {'min': min, 'max': max, 'value': numVal},
          message: message,
        );
      }
      return null;
    };
  }

  /// Alias for [valueRange].
  static NeatValidator<Object?> between(
    num min,
    num max, {
    String code = codeValueRange,
    String? message,
  }) =>
      valueRange(min, max, code: code, message: message);

  /// Validates that numeric value is strictly positive (> 0).
  static NeatValidator<Object?> positive({
    String code = codePositive,
    String? message,
  }) {
    return (Object? value) {
      if (value == null) return null;
      final numVal = _tryExtractNum(value);
      if (numVal == null) return null;
      if (numVal <= 0) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that numeric value is strictly negative (< 0).
  static NeatValidator<Object?> negative({
    String code = codeNegative,
    String? message,
  }) {
    return (Object? value) {
      if (value == null) return null;
      final numVal = _tryExtractNum(value);
      if (numVal == null) return null;
      if (numVal >= 0) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that numeric value is non-negative (>= 0).
  static NeatValidator<Object?> nonNegative({
    String code = codeNonNegative,
    String? message,
  }) {
    return (Object? value) {
      if (value == null) return null;
      final numVal = _tryExtractNum(value);
      if (numVal == null) return null;
      if (numVal < 0) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that numeric value is non-positive (<= 0).
  static NeatValidator<Object?> nonPositive({
    String code = codeNonPositive,
    String? message,
  }) {
    return (Object? value) {
      if (value == null) return null;
      final numVal = _tryExtractNum(value);
      if (numVal == null) return null;
      if (numVal > 0) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that value is an integer (no fractional decimal digits).
  static NeatValidator<Object?> integerOnly({
    String code = codeIntegerOnly,
    String? message,
  }) {
    return (Object? value) {
      if (value == null) return null;
      if (value is int) return null;
      if (value is double) {
        if (value % 1 != 0) {
          return NeatValidationError(code, message: message);
        }
        return null;
      }
      if (value is String) {
        final text = value.trim();
        if (text.isEmpty) return null;
        final parsed = num.tryParse(text);
        if (parsed == null || parsed % 1 != 0) {
          return NeatValidationError(code, message: message);
        }
      }
      return null;
    };
  }

  /// Validates that a number is an exact multiple of [step].
  static NeatValidator<Object?> multipleOf(
    num step, {
    String code = codeMultipleOf,
    String? message,
  }) {
    return (Object? value) {
      if (value == null) return null;
      final numVal = _tryExtractNum(value);
      if (numVal == null) return null;
      if (step == 0 || (numVal % step) != 0) {
        return NeatValidationError(
          code,
          params: {'step': step},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates maximum decimal places allowed for a number or numeric string.
  static NeatValidator<Object?> decimalPrecision(
    int maxDecimals, {
    String code = codeDecimalPrecision,
    String? message,
  }) {
    return (Object? value) {
      if (value == null) return null;
      final str = value is num ? value.toString() : value is String ? value : null;
      if (str == null || str.isEmpty) return null;
      if (str.contains('.')) {
        final decimals = str.split('.').last.length;
        if (decimals > maxDecimals) {
          return NeatValidationError(
            code,
            params: {'maxDecimals': maxDecimals},
            message: message,
          );
        }
      }
      return null;
    };
  }

  // --- Pattern & Regex ---

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

  // --- Date & Time Validators ---

  /// Validates that a date occurs in the past.
  static NeatValidator<Object?> pastDate({
    String code = codePastDate,
    String? message,
  }) {
    return (Object? value) {
      if (value is! DateTime?) return null;
      if (value == null) return null;
      if (!value.isBefore(DateTime.now())) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that a date occurs in the future.
  static NeatValidator<Object?> futureDate({
    String code = codeFutureDate,
    String? message,
  }) {
    return (Object? value) {
      if (value is! DateTime?) return null;
      if (value == null) return null;
      if (!value.isAfter(DateTime.now())) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that a date is within [min] and [max].
  static NeatValidator<Object?> dateRange(
    DateTime min,
    DateTime max, {
    String code = codeDateRange,
    String? message,
  }) {
    return (Object? value) {
      if (value is! DateTime?) return null;
      if (value == null) return null;
      if (value.isBefore(min) || value.isAfter(max)) {
        return NeatValidationError(
          code,
          params: {'min': min.toIso8601String(), 'max': max.toIso8601String()},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates that a string is a valid calendar date formatted as [format] (e.g. `DD/MM/YYYY`, `MM/DD/YYYY`, `YYYY-MM-DD`).
  ///
  /// Checks calendar validity (valid month 1-12, days 1-31, leap years, days per month)
  /// and optional bounds ([mustBePast], [mustBeFuture], [minYear], [maxYear], [minAge], [maxAge]).
  static NeatValidator<Object?> dateString({
    String format = 'DD/MM/YYYY',
    bool mustBePast = false,
    bool mustBeFuture = false,
    int? minYear,
    int? maxYear,
    int? minAge,
    int? maxAge,
    String code = codeDateString,
    String? message,
  }) {
    return (Object? value) {
      if (value == null) return null;
      final text = value.toString().trim();
      if (text.isEmpty) return null;

      final cleanFormat = format.toUpperCase().replaceAll('-', '/');
      final cleanText = text.replaceAll('-', '/');

      final parts = cleanText.split('/');
      final formatParts = cleanFormat.split('/');

      if (parts.length != formatParts.length ||
          parts.any((p) => int.tryParse(p) == null)) {
        return NeatValidationError(
          code,
          message: message ?? 'Định dạng ngày không hợp lệ ($format)',
        );
      }

      var day = 0;
      var month = 0;
      var year = 0;
      for (var i = 0; i < formatParts.length; i++) {
        final f = formatParts[i];
        final p = parts[i];
        if (p.length != f.length) {
          return NeatValidationError(
            code,
            message: message ?? 'Định dạng ngày không hợp lệ ($format)',
          );
        }
        final val = int.parse(p);
        if (f == 'DD') {
          day = val;
        } else if (f == 'MM') {
          month = val;
        } else if (f == 'YYYY') {
          year = val;
        } else if (f == 'YY') {
          year = 2000 + val;
        }
      }

      if (month < 1 || month > 12) {
        return NeatValidationError(
          code,
          message: message ?? 'Tháng không hợp lệ (01-12)',
        );
      }

      const daysInMonth = [
        0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
      ];
      final isLeapYear =
          (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      final maxDays = (month == 2 && isLeapYear) ? 29 : daysInMonth[month];

      if (day < 1 || day > maxDays) {
        return NeatValidationError(
          code,
          message: message ?? 'Ngày không hợp lệ trong tháng (01-$maxDays)',
        );
      }

      if (minYear != null && year < minYear) {
        return NeatValidationError(
          code,
          message: message ?? 'Năm phải từ $minYear trở lên',
        );
      }
      if (maxYear != null && year > maxYear) {
        return NeatValidationError(
          code,
          message: message ?? 'Năm tối đa là $maxYear',
        );
      }

      final parsedDate = DateTime(year, month, day);
      final now = DateTime.now();

      if (mustBePast && !parsedDate.isBefore(now)) {
        return NeatValidationError(
          code,
          message: message ?? 'Ngày phải ở trong quá khứ',
        );
      }
      if (mustBeFuture && !parsedDate.isAfter(now)) {
        return NeatValidationError(
          code,
          message: message ?? 'Ngày phải ở trong tương lai',
        );
      }

      if (minAge != null) {
        var age = now.year - parsedDate.year;
        if (now.month < parsedDate.month ||
            (now.month == parsedDate.month && now.day < parsedDate.day)) {
          age--;
        }
        if (age < minAge) {
          return NeatValidationError(
            code,
            params: {'minAge': minAge, 'actualAge': age},
            message: message ?? 'Độ tuổi tối thiểu là $minAge tuổi',
          );
        }
      }
      if (maxAge != null) {
        var age = now.year - parsedDate.year;
        if (now.month < parsedDate.month ||
            (now.month == parsedDate.month && now.day < parsedDate.day)) {
          age--;
        }
        if (age > maxAge) {
          return NeatValidationError(
            code,
            params: {'maxAge': maxAge, 'actualAge': age},
            message: message ?? 'Độ tuổi tối đa là $maxAge tuổi',
          );
        }
      }

      return null;
    };
  }

  /// Validates that a string is a valid 24-hour time (e.g. `HH:mm` or `HH:mm:ss`).
  static NeatValidator<Object?> timeString({
    String format = 'HH:mm',
    String code = codeTimeString,
    String? message,
  }) {
    return (Object? value) {
      if (value == null) return null;
      final text = value.toString().trim();
      if (text.isEmpty) return null;

      final parts = text.split(':');
      final formatParts = format.split(':');

      if (parts.length != formatParts.length ||
          parts.any((p) => int.tryParse(p) == null || p.length != 2)) {
        return NeatValidationError(
          code,
          message: message ?? 'Định dạng giờ không hợp lệ ($format)',
        );
      }

      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = parts.length > 2 ? int.parse(parts[2]) : 0;

      if (hours < 0 ||
          hours > 23 ||
          minutes < 0 ||
          minutes > 59 ||
          seconds < 0 ||
          seconds > 59) {
        return NeatValidationError(
          code,
          message: message ?? 'Thời gian không hợp lệ',
        );
      }

      return null;
    };
  }

  /// Validates that a credit card expiry string (`MM/YY` or `MM/YYYY`) is valid and not expired.
  static NeatValidator<Object?> creditCardExpiry({
    String code = codeCreditCardExpiry,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;

      final clean = value.trim().replaceAll('-', '/');
      final parts = clean.split('/');
      if (parts.length != 2 || parts.any((p) => int.tryParse(p) == null)) {
        return NeatValidationError(
          code,
          message: message ?? 'Hạn thẻ không hợp lệ (MM/YY)',
        );
      }

      final month = int.parse(parts[0]);
      var year = int.parse(parts[1]);
      if (parts[1].length == 2) {
        year += 2000;
      }

      if (month < 1 || month > 12) {
        return NeatValidationError(
          code,
          message: message ?? 'Tháng hết hạn không hợp lệ (01-12)',
        );
      }

      final now = DateTime.now();
      final lastDayOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);
      if (lastDayOfMonth.isBefore(now)) {
        return NeatValidationError(
          code,
          message: message ?? 'Thẻ đã hết hạn sử dụng',
        );
      }

      return null;
    };
  }

  // --- Consent & Boolean Validators ---

  /// Validates that a boolean field is explicitly `true` (e.g. Terms & Conditions acceptance).
  static NeatValidator<Object?> mustBeTrue({
    String code = codeMustBeTrue,
    String? message,
  }) {
    return (Object? value) {
      if (value != true) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that a boolean field is explicitly `false`.
  static NeatValidator<Object?> mustBeFalse({
    String code = codeMustBeFalse,
    String? message,
  }) {
    return (Object? value) {
      if (value != false) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  // --- Collections / Lists & Choice Validators ---

  /// Validates that an Iterable has at least [min] items.
  static NeatValidator<Object?> minItems(
    int min, {
    String code = codeMinItems,
    String? message,
  }) {
    return (Object? value) {
      if (value is! Iterable?) return null;
      if (value == null) return null;
      if (value.length < min) {
        return NeatValidationError(
          code,
          params: {'min': min, 'count': min},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates that an Iterable has at most [max] items.
  static NeatValidator<Object?> maxItems(
    int max, {
    String code = codeMaxItems,
    String? message,
  }) {
    return (Object? value) {
      if (value is! Iterable?) return null;
      if (value == null) return null;
      if (value.length > max) {
        return NeatValidationError(
          code,
          params: {'max': max, 'count': max},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates that an Iterable contains no duplicate elements.
  static NeatValidator<Object?> uniqueItems({
    String code = codeUniqueItems,
    String? message,
  }) {
    return (Object? value) {
      if (value is! Iterable?) return null;
      if (value == null) return null;
      final set = value.toSet();
      if (set.length != value.length) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that value belongs to the [allowedValues] collection.
  static NeatValidator<T> oneOf<T>(
    Iterable<T> allowedValues, {
    String code = codeOneOf,
    String? message,
  }) {
    final set = allowedValues.toSet();
    return (T? value) {
      if (value == null) return null;
      if (!set.contains(value)) {
        return NeatValidationError(
          code,
          params: {'allowedValues': allowedValues.toList()},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates that value does NOT belong to the [forbiddenValues] collection.
  static NeatValidator<T> noneOf<T>(
    Iterable<T> forbiddenValues, {
    String code = codeNoneOf,
    String? message,
  }) {
    final set = forbiddenValues.toSet();
    return (T? value) {
      if (value == null) return null;
      if (set.contains(value)) {
        return NeatValidationError(
          code,
          params: {'forbiddenValues': forbiddenValues.toList()},
          message: message,
        );
      }
      return null;
    };
  }

  // --- Security, Network & Format Validators ---

  /// Validates that string contains no HTML or Script tags (anti-XSS).
  static NeatValidator<Object?> noHtml({
    String code = codeNoHtml,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (_htmlTagRegExp.hasMatch(value)) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates IPv4 address string (e.g. `192.168.1.1`).
  static NeatValidator<Object?> ipv4({
    String code = codeIp,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (!_ipv4RegExp.hasMatch(value.trim())) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates IPv6 address string.
  static NeatValidator<Object?> ipv6({
    String code = codeIp,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (!_ipv6RegExp.hasMatch(value.trim())) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates either an IPv4 or IPv6 address string.
  static NeatValidator<Object?> ipAddress({
    String code = codeIp,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      final trimmed = value.trim();
      if (!_ipv4RegExp.hasMatch(trimmed) && !_ipv6RegExp.hasMatch(trimmed)) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates UUID (GUID) string.
  static NeatValidator<Object?> uuid({
    int? version,
    String code = codeUuid,
    String? message,
  }) {
    final regex = version == null ? _uuidAnyVersionRegExp : _uuidRegExp;
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value.trim())) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates Hex Color string (`#FFF`, `#RRGGBB`, `#AARRGGBB`).
  static NeatValidator<Object?> hexColor({
    bool leadingHashRequired = false,
    String code = codeHexColor,
    String? message,
  }) {
    final regex = leadingHashRequired
        ? _hexColorWithHashRegExp
        : _hexColorAnyRegExp;
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value.trim())) {
        return NeatValidationError(code, message: message);
      }
      return null;
    };
  }

  /// Validates that a string is valid parseable JSON.
  static NeatValidator<Object?> jsonString({
    String code = codeJson,
    String? message,
  }) {
    return (Object? value) {
      if (value is! String?) return null;
      if (value == null || value.isEmpty) return null;
      try {
        jsonDecode(value);
        return null;
      } on Object catch (_) {
        return NeatValidationError(code, message: message);
      }
    };
  }

  // --- Custom Validator Builder ---

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
