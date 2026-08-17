import 'dart:math' as math;
import 'package:flutter/services.dart';

/// Card brand/type detected by [NeatCardFormatter].
enum NeatCardType {
  /// Visa card (starts with 4).
  visa,

  /// Mastercard (starts with 51-55 or 2221-2720).
  mastercard,

  /// American Express (starts with 34 or 37).
  amex,

  /// JCB card (starts with 35).
  jcb,

  /// Discover card (starts with 6011, 644-649, 65).
  discover,

  /// Other or unrecognized card brand.
  unknown;

  /// Whether the card type is [visa].
  bool get isVisa => this == NeatCardType.visa;

  /// Whether the card type is [mastercard].
  bool get isMastercard => this == NeatCardType.mastercard;

  /// Whether the card type is [amex].
  bool get isAmex => this == NeatCardType.amex;

  /// Whether the card type is [jcb].
  bool get isJcb => this == NeatCardType.jcb;

  /// Whether the card type is [discover].
  bool get isDiscover => this == NeatCardType.discover;

  /// Whether the card type is [unknown].
  bool get isUnknown => this == NeatCardType.unknown;
}

/// Date formats supported by [NeatDateFormatter].
enum NeatDateFormat {
  /// Day / Month / Year (e.g. 31/12/2025).
  ddMMyyyy,

  /// Year / Month / Day (e.g. 2025/12/31).
  yyyyMMdd,

  /// Month / Day / Year (e.g. 12/31/2025).
  mmDdYyyy,

  /// Month / Year for expiration dates (e.g. 12/28).
  mmYy;

  /// Total number of digits required for this date format.
  int get digitCount {
    switch (this) {
      case NeatDateFormat.ddMMyyyy:
      case NeatDateFormat.yyyyMMdd:
      case NeatDateFormat.mmDdYyyy:
        return 8;
      case NeatDateFormat.mmYy:
        return 4;
    }
  }
}

/// A flexible, zero-dependency mask formatter supporting custom patterns
/// such as `(###) ###-####` or `AA-####`.
class NeatMaskFormatter extends TextInputFormatter {
  /// Creates a mask formatter with a [mask] string and optional [filter] rules.
  ///
  /// By default:
  /// - `#` matches any digit (`[0-9]`)
  /// - `A` matches any letter (`[a-zA-Z]`)
  /// - `*` matches any character
  NeatMaskFormatter({
    required this.mask,
    Map<String, RegExp>? filter,
  }) : filter = filter ??
            {
              '#': RegExp('[0-9]'),
              'A': RegExp('[a-zA-Z]'),
              '*': RegExp('.'),
            };

  /// The mask pattern to format against (e.g. `(###) ###-####`).
  final String mask;

  /// Map of placeholder characters to their respective regex matchers.
  final Map<String, RegExp> filter;

  /// Returns whether a character at [maskIndex] in the mask is a placeholder.
  bool _isPlaceholder(int maskIndex) {
    if (maskIndex >= mask.length || maskIndex < 0) return false;
    return filter.containsKey(mask[maskIndex]);
  }

  /// Extracts the unmasked text from a given [formattedText].
  String getUnmaskedText(String formattedText) {
    if (formattedText.isEmpty) return '';
    final buffer = StringBuffer();
    var maskIndex = 0;
    for (var i = 0; i < formattedText.length && maskIndex < mask.length; i++) {
      final char = formattedText[i];
      final maskChar = mask[maskIndex];
      if (_isPlaceholder(maskIndex)) {
        final regex = filter[maskChar]!;
        if (regex.hasMatch(char)) {
          buffer.write(char);
          maskIndex++;
        }
      } else {
        if (char == maskChar) {
          maskIndex++;
        }
      }
    }
    return buffer.toString();
  }

  /// Formats raw unmasked text into the mask pattern.
  String format(String rawText) {
    if (rawText.isEmpty) return '';
    final buffer = StringBuffer();
    var rawIndex = 0;

    for (var maskIndex = 0;
        maskIndex < mask.length && rawIndex < rawText.length;
        maskIndex++) {
      final maskChar = mask[maskIndex];
      if (filter.containsKey(maskChar)) {
        final regex = filter[maskChar]!;
        while (rawIndex < rawText.length) {
          final char = rawText[rawIndex++];
          if (regex.hasMatch(char)) {
            buffer.write(char);
            break;
          }
        }
      } else {
        buffer.write(maskChar);
      }
    }

    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Handle backspacing over a fixed separator
    var workingNewValue = newValue;
    if (oldValue.text.length > newValue.text.length &&
        oldValue.selection.isCollapsed &&
        newValue.selection.isCollapsed) {
      final deletedIndex = newValue.selection.baseOffset;
      if (deletedIndex >= 0 && deletedIndex < oldValue.text.length) {
        final deletedChar = oldValue.text[deletedIndex];
        if (deletedIndex < mask.length && !_isPlaceholder(deletedIndex)) {
          if (deletedChar == mask[deletedIndex] && deletedIndex > 0) {
            final before = newValue.text.substring(0, deletedIndex - 1);
            final after = newValue.text.substring(deletedIndex);
            workingNewValue = TextEditingValue(
              text: '$before$after',
              selection: TextSelection.collapsed(offset: deletedIndex - 1),
            );
          }
        }
      }
    }

    // Extract raw payload characters and count how many appear before cursor
    final textBeforeCursor = workingNewValue.selection.baseOffset >= 0
        ? workingNewValue.text.substring(
            0,
            math.min(
              workingNewValue.selection.baseOffset,
              workingNewValue.text.length,
            ),
          )
        : workingNewValue.text;

    final rawBuffer = StringBuffer();
    var rawCharsBeforeCursor = 0;
    var maskIndex = 0;

    for (var i = 0; i < workingNewValue.text.length; i++) {
      final char = workingNewValue.text[i];
      final isBeforeCursor = i < textBeforeCursor.length;

      // If current character matches the static mask literal, consume it and continue
      if (maskIndex < mask.length &&
          !_isPlaceholder(maskIndex) &&
          char == mask[maskIndex]) {
        maskIndex++;
        continue;
      }

      // Advance mask index past any fixed literals
      while (maskIndex < mask.length && !_isPlaceholder(maskIndex)) {
        maskIndex++;
      }

      // Check against current placeholder
      if (maskIndex < mask.length && _isPlaceholder(maskIndex)) {
        final regex = filter[mask[maskIndex]]!;
        if (regex.hasMatch(char)) {
          rawBuffer.write(char);
          if (isBeforeCursor) rawCharsBeforeCursor++;
          maskIndex++;
          continue;
        }
      }

      // If character matches any subsequent placeholder in the mask
      var tempIndex = maskIndex + 1;
      while (tempIndex < mask.length) {
        if (_isPlaceholder(tempIndex)) {
          final regex = filter[mask[tempIndex]]!;
          if (regex.hasMatch(char)) {
            rawBuffer.write(char);
            if (isBeforeCursor) rawCharsBeforeCursor++;
            maskIndex = tempIndex + 1;
            break;
          }
        }
        tempIndex++;
      }
    }

    final rawText = rawBuffer.toString();
    final formattedBuffer = StringBuffer();
    var rawIndex = 0;
    var cursorPosition = 0;
    var rawCountForCursor = 0;

    for (var mIndex = 0; mIndex < mask.length; mIndex++) {
      if (rawIndex >= rawText.length) {
        break;
      }

      final maskChar = mask[mIndex];
      if (_isPlaceholder(mIndex)) {
        formattedBuffer.write(rawText[rawIndex]);
        rawIndex++;
        if (rawCountForCursor < rawCharsBeforeCursor) {
          rawCountForCursor++;
          cursorPosition = formattedBuffer.length;
        }
      } else {
        formattedBuffer.write(maskChar);
        if (rawCountForCursor == rawCharsBeforeCursor && cursorPosition == 0) {
          cursorPosition = formattedBuffer.length;
        }
      }
    }

    if (rawCharsBeforeCursor >= rawText.length) {
      cursorPosition = formattedBuffer.length;
    }

    final formattedText = formattedBuffer.toString();
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: math.min(cursorPosition, formattedText.length),
      ),
    );
  }
}

/// A real-time currency formatter supporting thousands separators, decimal points,
/// custom prefix/suffix, and number extraction.
class NeatCurrencyFormatter extends TextInputFormatter {
  /// Creates a currency formatter.
  NeatCurrencyFormatter({
    this.thousandSeparator = ',',
    this.decimalSeparator = '.',
    this.prefix = '',
    this.suffix = '',
    this.allowDecimals = false,
    this.decimalDigits = 2,
    this.allowNegative = false,
    this.maxIntegerDigits = 15,
  }) : assert(
          thousandSeparator != decimalSeparator,
          'thousandSeparator and decimalSeparator cannot be identical',
        );

  /// Thousand separator character (e.g. `,` or `.`).
  final String thousandSeparator;

  /// Decimal separator character (e.g. `.` or `,`).
  final String decimalSeparator;

  /// Prefix string (e.g. `$` or `VND `).
  final String prefix;

  /// Suffix string (e.g. ` ₫` or ` USD`).
  final String suffix;

  /// Whether decimal numbers are allowed.
  final bool allowDecimals;

  /// Maximum number of digits allowed after the decimal separator.
  final int decimalDigits;

  /// Whether negative numbers are allowed.
  final bool allowNegative;

  /// Maximum number of digits allowed for the integer portion.
  final int maxIntegerDigits;

  /// Extracts the numeric value ([num]) from a [formattedText] string.
  ///
  /// Returns `null` if the text contains no valid number.
  num? getNumericValue(String formattedText) {
    if (formattedText.isEmpty) return null;

    var cleaned = formattedText;
    if (prefix.isNotEmpty && cleaned.startsWith(prefix)) {
      cleaned = cleaned.substring(prefix.length);
    }
    if (suffix.isNotEmpty && cleaned.endsWith(suffix)) {
      cleaned = cleaned.substring(0, cleaned.length - suffix.length);
    }

    final isNegative = allowNegative && cleaned.contains('-');
    cleaned = cleaned.replaceAll(thousandSeparator, '').replaceAll('-', '');

    if (allowDecimals && decimalSeparator != '.') {
      cleaned = cleaned.replaceAll(decimalSeparator, '.');
    }

    final trimmed = cleaned.trim();
    if (trimmed.isEmpty || trimmed == '.') return null;

    final parsed = num.tryParse(trimmed);
    if (parsed == null) return null;
    return isNegative ? -parsed : parsed;
  }

  /// Formats a [num] into a currency string representation.
  String formatValue(num value) {
    final isNegative = value < 0;
    final absVal = value.abs();

    String integerPart;
    var decimalPart = '';

    if (allowDecimals && (absVal is double || decimalDigits > 0)) {
      final fixed = absVal.toStringAsFixed(decimalDigits);
      final parts = fixed.split('.');
      integerPart = parts[0];
      if (parts.length > 1 && parts[1] != '0' * decimalDigits) {
        decimalPart = '$decimalSeparator${parts[1]}';
      }
    } else {
      integerPart = absVal.toInt().toString();
    }

    final formattedInteger = _formatIntegerPart(integerPart);
    final sign = isNegative ? '-' : '';
    return '$prefix$sign$formattedInteger$decimalPart$suffix';
  }

  String _formatIntegerPart(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    final len = digits.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write(thousandSeparator);
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Strip prefix and suffix from raw input to process core digits
    final text = newValue.text;
    final isNegative = allowNegative && text.contains('-');

    // Split integer and decimal parts
    var rawInteger = '';
    var rawDecimal = '';
    var hasDecimal = false;

    if (allowDecimals && text.contains(decimalSeparator)) {
      hasDecimal = true;
      final parts = text.split(decimalSeparator);
      rawInteger = parts[0].replaceAll(RegExp('[^0-9]'), '');
      if (parts.length > 1) {
        rawDecimal = parts[1].replaceAll(RegExp('[^0-9]'), '');
        if (rawDecimal.length > decimalDigits) {
          rawDecimal = rawDecimal.substring(0, decimalDigits);
        }
      }
    } else {
      final baseText = text.contains(decimalSeparator)
          ? text.split(decimalSeparator)[0]
          : text;
      rawInteger = baseText.replaceAll(RegExp('[^0-9]'), '');
    }

    if (rawInteger.length > maxIntegerDigits) {
      rawInteger = rawInteger.substring(0, maxIntegerDigits);
    }

    // Count raw digits before cursor in newValue to place cursor accurately
    final cursorIndex = newValue.selection.baseOffset;
    final textBeforeCursor = cursorIndex >= 0
        ? text.substring(0, math.min(cursorIndex, text.length))
        : text;
    final digitsBeforeCursor =
        textBeforeCursor.replaceAll(RegExp('[^0-9]'), '').length;
    final isCursorAfterDecimal = hasDecimal &&
        textBeforeCursor.contains(decimalSeparator) &&
        allowDecimals;

    // Remove leading zeros for clean format (unless integer is just '0')
    if (rawInteger.length > 1 && rawInteger.startsWith('0')) {
      rawInteger = rawInteger.replaceFirst(RegExp('^0+'), '');
      if (rawInteger.isEmpty) rawInteger = '0';
    }

    // Default to '0' if empty but has decimal (e.g. user typed ".5")
    if (rawInteger.isEmpty && hasDecimal) {
      rawInteger = '0';
    }

    final formattedInteger = _formatIntegerPart(rawInteger);
    final sign = isNegative ? '-' : '';
    final formattedDecimal = hasDecimal ? '$decimalSeparator$rawDecimal' : '';
    final formattedText =
        '$prefix$sign$formattedInteger$formattedDecimal$suffix';

    // Calculate new cursor position
    var newCursorOffset = prefix.length + (isNegative ? 1 : 0);
    var countedDigits = 0;

    if (isCursorAfterDecimal) {
      // Cursor is in decimal area
      final intAndDecFormatted =
          '$prefix$sign$formattedInteger$decimalSeparator';
      final decDigitsBefore = textBeforeCursor
          .split(decimalSeparator)
          .last
          .replaceAll(RegExp('[^0-9]'), '')
          .length;
      newCursorOffset = math.min(
        intAndDecFormatted.length + decDigitsBefore,
        formattedText.length - suffix.length,
      );
    } else {
      // Cursor is in integer area
      for (var i = newCursorOffset; i < formattedText.length; i++) {
        if (countedDigits >= digitsBeforeCursor) {
          newCursorOffset = i;
          break;
        }
        final char = formattedText[i];
        if (RegExp('[0-9]').hasMatch(char)) {
          countedDigits++;
        }
        newCursorOffset = i + 1;
      }
    }

    newCursorOffset = math.min(
      math.max(prefix.length + (isNegative ? 1 : 0), newCursorOffset),
      formattedText.length - suffix.length,
    );

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }
}

/// A smart payment card formatter that auto-detects card brand
/// (Visa, Mastercard, Amex, JCB, Discover) and formats digits with spacing.
class NeatCardFormatter extends TextInputFormatter {
  /// Creates a card number formatter with optional [separator].
  NeatCardFormatter({this.separator = ' '});

  /// Separator character placed between card digit groups (defaults to space `' '`).
  final String separator;

  /// Detects the [NeatCardType] for a given [cardNumber] string.
  static NeatCardType detectCardType(String cardNumber) {
    final clean = cardNumber.replaceAll(RegExp('[^0-9]'), '');
    if (clean.isEmpty) return NeatCardType.unknown;

    if (clean.startsWith('4')) {
      return NeatCardType.visa;
    }

    if (clean.startsWith(RegExp('^5[1-5]')) ||
        (clean.length >= 4 &&
            int.tryParse(clean.substring(0, 4)) != null &&
            int.parse(clean.substring(0, 4)) >= 2221 &&
            int.parse(clean.substring(0, 4)) <= 2720)) {
      return NeatCardType.mastercard;
    }

    if (clean.startsWith('34') || clean.startsWith('37')) {
      return NeatCardType.amex;
    }

    if (clean.startsWith('35')) {
      return NeatCardType.jcb;
    }

    if (clean.startsWith('6011') ||
        clean.startsWith(RegExp('^64[4-9]')) ||
        clean.startsWith('65')) {
      return NeatCardType.discover;
    }

    return NeatCardType.unknown;
  }

  /// Extracts digits-only card number string.
  static String getCleanCardNumber(String text) {
    return text.replaceAll(RegExp('[^0-9]'), '');
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final clean = getCleanCardNumber(newValue.text);
    if (clean.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final cardType = detectCardType(clean);
    final isAmex = cardType.isAmex;
    final maxDigits = isAmex ? 15 : 19;
    final digits =
        clean.length > maxDigits ? clean.substring(0, maxDigits) : clean;

    final buffer = StringBuffer();
    if (isAmex) {
      // 4-6-5 format (American Express)
      for (var i = 0; i < digits.length; i++) {
        if (i == 4 || i == 10) buffer.write(separator);
        buffer.write(digits[i]);
      }
    } else {
      // 4-4-4-4 format (Standard cards, up to 19 digits)
      for (var i = 0; i < digits.length; i++) {
        if (i > 0 && i % 4 == 0) buffer.write(separator);
        buffer.write(digits[i]);
      }
    }

    // Cursor position preservation
    final cursorIndex = newValue.selection.baseOffset;
    final textBeforeCursor = cursorIndex >= 0
        ? newValue.text.substring(0, math.min(cursorIndex, newValue.text.length))
        : newValue.text;
    final digitsBefore =
        textBeforeCursor.replaceAll(RegExp('[^0-9]'), '').length;

    final formattedText = buffer.toString();
    var newCursorOffset = 0;
    var countedDigits = 0;

    for (var i = 0; i < formattedText.length; i++) {
      if (countedDigits >= digitsBefore) {
        newCursorOffset = i;
        break;
      }
      if (RegExp('[0-9]').hasMatch(formattedText[i])) {
        countedDigits++;
      }
      newCursorOffset = i + 1;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: math.min(newCursorOffset, formattedText.length),
      ),
    );
  }
}

/// A date formatter supporting `dd/MM/yyyy`, `yyyy/MM/dd`, `mm/dd/yyyy`, and `mm/yy`
/// with boundary clamping for days and months.
class NeatDateFormatter extends TextInputFormatter {
  /// Creates a date formatter with specified [format] and [separator].
  NeatDateFormatter({
    this.format = NeatDateFormat.ddMMyyyy,
    this.separator = '/',
    this.clampDays = true,
  });

  /// Date layout structure.
  final NeatDateFormat format;

  /// Date separator character (defaults to `/`).
  final String separator;

  /// Whether to automatically clamp invalid day numbers (>31) or months (>12).
  final bool clampDays;

  /// Parses the formatted date string into a [DateTime] object, or returns `null` if invalid.
  DateTime? getParsedDate(String text) {
    final digits = text.replaceAll(RegExp('[^0-9]'), '');
    if (digits.length != format.digitCount) return null;

    try {
      int year;
      int month;
      int day;
      switch (format) {
        case NeatDateFormat.ddMMyyyy:
          day = int.parse(digits.substring(0, 2));
          month = int.parse(digits.substring(2, 4));
          year = int.parse(digits.substring(4, 8));
        case NeatDateFormat.yyyyMMdd:
          year = int.parse(digits.substring(0, 4));
          month = int.parse(digits.substring(4, 6));
          day = int.parse(digits.substring(6, 8));
        case NeatDateFormat.mmDdYyyy:
          month = int.parse(digits.substring(0, 2));
          day = int.parse(digits.substring(2, 4));
          year = int.parse(digits.substring(4, 8));
        case NeatDateFormat.mmYy:
          month = int.parse(digits.substring(0, 2));
          day = 1;
          final shortYear = int.parse(digits.substring(2, 4));
          year = 2000 + shortYear;
      }
      if (month < 1 || month > 12 || day < 1 || day > 31 || year < 1000 || year > 9999) {
        return null;
      }

      // Strict date validation (catches Feb 30, April 31, non-leap year Feb 29)
      final parsed = DateTime(year, month, day);
      if (parsed.year != year || parsed.month != month || parsed.day != day) {
        return null;
      }
      return parsed;
    } on Exception catch (_) {
      return null;
    }
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final clean = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    final maxDigits = format.digitCount;
    final digits =
        clean.length > maxDigits ? clean.substring(0, maxDigits) : clean;

    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer();
    switch (format) {
      case NeatDateFormat.ddMMyyyy:
      case NeatDateFormat.mmDdYyyy:
        for (var i = 0; i < digits.length; i++) {
          if (i == 2 || i == 4) buffer.write(separator);
          buffer.write(digits[i]);
        }
      case NeatDateFormat.yyyyMMdd:
        for (var i = 0; i < digits.length; i++) {
          if (i == 4 || i == 6) buffer.write(separator);
          buffer.write(digits[i]);
        }
      case NeatDateFormat.mmYy:
        for (var i = 0; i < digits.length; i++) {
          if (i == 2) buffer.write(separator);
          buffer.write(digits[i]);
        }
    }

    // Cursor position calculation
    final cursorIndex = newValue.selection.baseOffset;
    final textBeforeCursor = cursorIndex >= 0
        ? newValue.text.substring(0, math.min(cursorIndex, newValue.text.length))
        : newValue.text;
    final digitsBefore =
        textBeforeCursor.replaceAll(RegExp('[^0-9]'), '').length;

    final formattedText = buffer.toString();
    var newCursorOffset = 0;
    var countedDigits = 0;

    for (var i = 0; i < formattedText.length; i++) {
      if (countedDigits >= digitsBefore) {
        newCursorOffset = i;
        break;
      }
      if (RegExp('[0-9]').hasMatch(formattedText[i])) {
        countedDigits++;
      }
      newCursorOffset = i + 1;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: math.min(newCursorOffset, formattedText.length),
      ),
    );
  }
}

class _NeatUpperCaseFormatter extends TextInputFormatter {
  const _NeatUpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class _NeatLowerCaseFormatter extends TextInputFormatter {
  const _NeatLowerCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}

/// A comprehensive suite of zero-dependency Flutter [TextInputFormatter] utilities
/// for masking, currency, payment cards, date inputs, and text casing.
abstract final class NeatInputFormatters {
  /// Creates a custom mask formatter (e.g. `(###) ###-####` or `AA-####`).
  static NeatMaskFormatter mask(
    String mask, {
    Map<String, RegExp>? filter,
  }) =>
      NeatMaskFormatter(mask: mask, filter: filter);

  /// Creates a real-time currency formatter with configurable thousand/decimal separators,
  /// prefix, suffix, and decimal bounds.
  static NeatCurrencyFormatter currency({
    String thousandSeparator = ',',
    String decimalSeparator = '.',
    String prefix = '',
    String suffix = '',
    bool allowDecimals = false,
    int decimalDigits = 2,
    bool allowNegative = false,
    int maxIntegerDigits = 15,
  }) =>
      NeatCurrencyFormatter(
        thousandSeparator: thousandSeparator,
        decimalSeparator: decimalSeparator,
        prefix: prefix,
        suffix: suffix,
        allowDecimals: allowDecimals,
        decimalDigits: decimalDigits,
        allowNegative: allowNegative,
        maxIntegerDigits: maxIntegerDigits,
      );

  /// Creates a smart credit / debit card formatter with auto-brand detection and spacing.
  static NeatCardFormatter creditCard({String separator = ' '}) =>
      NeatCardFormatter(separator: separator);

  /// Creates a date formatter (e.g. `dd/MM/yyyy`, `yyyy/MM/dd`, `mmYy`).
  static NeatDateFormatter date({
    NeatDateFormat format = NeatDateFormat.ddMMyyyy,
    String separator = '/',
    bool clampDays = true,
  }) =>
      NeatDateFormatter(
        format: format,
        separator: separator,
        clampDays: clampDays,
      );

  /// Converts all typed characters to uppercase (e.g. promo codes, license plates).
  static TextInputFormatter uppercase() => const _NeatUpperCaseFormatter();

  /// Converts all typed characters to lowercase (e.g. usernames, email handles).
  static TextInputFormatter lowercase() => const _NeatLowerCaseFormatter();

  /// Filters out all non-latin characters, allowing only `[a-zA-Z0-9_]`.
  static TextInputFormatter latinOnly() =>
      FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9_]'));

  /// Denies all whitespace characters.
  static TextInputFormatter noSpaces() =>
      FilteringTextInputFormatter.deny(RegExp(r'\s'));
}
