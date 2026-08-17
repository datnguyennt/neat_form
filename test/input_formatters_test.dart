import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neat_form/neat_form.dart';

void main() {
  group('NeatMaskFormatter - Exhaustive Tests', () {
    test('formats standard phone mask sequentially', () {
      final formatter = NeatInputFormatters.mask('(###) ###-####');

      var value = const TextEditingValue(text: '');
      final inputDigits = '0901234567';
      final expectedOutputs = [
        '(0',
        '(09',
        '(090',
        '(090) 1',
        '(090) 12',
        '(090) 123',
        '(090) 123-4',
        '(090) 123-45',
        '(090) 123-456',
        '(090) 123-4567',
      ];

      for (var i = 0; i < inputDigits.length; i++) {
        final newChar = inputDigits[i];
        final nextValue = TextEditingValue(
          text: '${value.text}$newChar',
          selection: TextSelection.collapsed(offset: value.text.length + 1),
        );
        value = formatter.formatEditUpdate(value, nextValue);
        expect(value.text, expectedOutputs[i]);
      }
    });

    test('handles backspace over fixed separator without getting stuck', () {
      final formatter = NeatInputFormatters.mask('(###) ###-####');

      // State: '(090) 1'
      const oldValue = TextEditingValue(
        text: '(090) 1',
        selection: TextSelection.collapsed(offset: 7),
      );

      // User presses backspace on '1' -> '(090) '
      const step1 = TextEditingValue(
        text: '(090) ',
        selection: TextSelection.collapsed(offset: 6),
      );
      final res1 = formatter.formatEditUpdate(oldValue, step1);
      expect(res1.text, '(090');

      // User presses backspace on '0' at '(090' -> text becomes '(09'
      const step2 = TextEditingValue(
        text: '(09',
        selection: TextSelection.collapsed(offset: 3),
      );
      final res2 = formatter.formatEditUpdate(res1, step2);
      expect(res2.text, '(09');
    });

    test('handles paste with invalid and non-matching characters', () {
      final formatter = NeatInputFormatters.mask('(###) ###-####');
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: 'Phone: +84 (090) 123-4567 Ext 888',
        selection: TextSelection.collapsed(offset: 33),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      // Extracts first 10 digits '8409012345'
      expect(result.text, '(840) 901-2345');
    });

    test('truncates input exceeding mask length', () {
      final formatter = NeatInputFormatters.mask('AA-##');
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: 'VN123456789',
        selection: TextSelection.collapsed(offset: 11),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'VN-12');
    });

    test('supports custom wildcard filter * and alphanumeric filter A', () {
      final formatter = NeatMaskFormatter(
        mask: 'ID-AA-**-##',
      );

      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: 'IDVN#@99',
        selection: TextSelection.collapsed(offset: 8),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'ID-VN-#@-99');
      expect(formatter.getUnmaskedText(result.text), 'VN#@99');
    });

    test('getUnmaskedText and format handle edge cases', () {
      final formatter = NeatInputFormatters.mask('(###) ###-####');
      expect(formatter.getUnmaskedText(''), '');
      expect(formatter.getUnmaskedText('---'), '');
      expect(formatter.getUnmaskedText('(123) 456-7890'), '1234567890');
      expect(formatter.format(''), '');
      expect(formatter.format('1234567890'), '(123) 456-7890');
      expect(formatter.format('123'), '(123');
    });

    test('mid-string replacement and cursor placement', () {
      final formatter = NeatInputFormatters.mask('###-###');

      const oldValue = TextEditingValue(
        text: '123-456',
        selection: TextSelection(baseOffset: 0, extentOffset: 3),
      );
      const newValue = TextEditingValue(
        text: '999-456',
        selection: TextSelection.collapsed(offset: 3),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '999-456');
    });
  });

  group('NeatCurrencyFormatter - Exhaustive Tests', () {
    test('formats large integer with dot separator and currency suffix', () {
      final formatter = NeatInputFormatters.currency(
        thousandSeparator: '.',
        decimalSeparator: ',',
        suffix: ' ₫',
      );

      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '123456789',
        selection: TextSelection.collapsed(offset: 9),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '123.456.789 ₫');
      expect(formatter.getNumericValue(result.text), 123456789);
    });

    test('formats float with decimals and dollar prefix', () {
      final formatter = NeatInputFormatters.currency(
        thousandSeparator: ',',
        decimalSeparator: '.',
        prefix: r'$',
        allowDecimals: true,
        decimalDigits: 2,
      );

      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '1250.75',
        selection: TextSelection.collapsed(offset: 7),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, r'$1,250.75');
      expect(formatter.getNumericValue(result.text), 1250.75);
    });

    test('handles leading dot gracefully when typing .5', () {
      final formatter = NeatInputFormatters.currency(
        prefix: r'$',
        allowDecimals: true,
      );

      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '.5',
        selection: TextSelection.collapsed(offset: 2),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, r'$0.5');
      expect(formatter.getNumericValue(result.text), 0.5);
    });

    test('cleans leading zeros and prevents 000500', () {
      final formatter = NeatInputFormatters.currency(prefix: r'$');

      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '000500',
        selection: TextSelection.collapsed(offset: 6),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, r'$500');
    });

    test('handles zero input correctly', () {
      final formatter = NeatInputFormatters.currency(suffix: ' ₫');

      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '0 ₫');
      expect(formatter.getNumericValue(result.text), 0);
    });

    test('handles negative currency values when allowNegative is true', () {
      final formatter = NeatInputFormatters.currency(
        prefix: r'$',
        allowNegative: true,
      );

      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '-250',
        selection: TextSelection.collapsed(offset: 4),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, r'$-250');
      expect(formatter.getNumericValue(result.text), -250);
    });

    test('getNumericValue edge cases return null safely', () {
      final formatter = NeatInputFormatters.currency(
        prefix: r'$',
        suffix: ' USD',
        allowNegative: true,
      );

      expect(formatter.getNumericValue(''), isNull);
      expect(formatter.getNumericValue(r'$'), isNull);
      expect(formatter.getNumericValue(r'$-'), isNull);
      expect(formatter.getNumericValue(r'$- USD'), isNull);
      expect(formatter.getNumericValue(r'$0 USD'), 0);
      expect(formatter.getNumericValue(r'$-500 USD'), -500);
      expect(formatter.getNumericValue('invalid'), isNull);
    });

    test('formatValue helper formats numbers correctly', () {
      final formatter = NeatInputFormatters.currency(
        thousandSeparator: '.',
        decimalSeparator: ',',
        suffix: ' ₫',
        allowDecimals: true,
        decimalDigits: 2,
      );

      expect(formatter.formatValue(1500000), '1.500.000 ₫');
      expect(formatter.formatValue(1500.5), '1.500,50 ₫');
      expect(formatter.formatValue(0), '0 ₫');
      expect(formatter.formatValue(-500), '-500 ₫');
    });

    test('truncates pasted decimal values if allowDecimals is false', () {
      final formatter = NeatInputFormatters.currency(
        thousandSeparator: ',',
        prefix: r'$',
        allowDecimals: false,
      );

      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '1250.99',
        selection: TextSelection.collapsed(offset: 7),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, r'$1,250');
    });

    test('respects maxIntegerDigits bound', () {
      final formatter = NeatInputFormatters.currency(
        prefix: r'$',
        maxIntegerDigits: 5,
      );

      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '1234567890',
        selection: TextSelection.collapsed(offset: 10),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, r'$12,345');
    });
  });

  group('NeatCardFormatter - Exhaustive Tests', () {
    test('detects and formats Visa card (starts with 4)', () {
      final formatter = NeatInputFormatters.creditCard();
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '4111222233334444',
        selection: TextSelection.collapsed(offset: 16),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '4111 2222 3333 4444');
      expect(NeatCardFormatter.detectCardType(result.text), NeatCardType.visa);
      expect(NeatCardType.visa.isVisa, isTrue);
      expect(NeatCardType.visa.isMastercard, isFalse);
    });

    test('detects and formats American Express card (4-6-5 format)', () {
      final formatter = NeatInputFormatters.creditCard();
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '341234567890123',
        selection: TextSelection.collapsed(offset: 15),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '3412 345678 90123');
      expect(NeatCardFormatter.detectCardType(result.text), NeatCardType.amex);
      expect(NeatCardType.amex.isAmex, isTrue);
    });

    test('detects and formats Mastercard (starts with 51-55 or 2221-2720)', () {
      expect(NeatCardFormatter.detectCardType('5123456789012345'), NeatCardType.mastercard);
      expect(NeatCardFormatter.detectCardType('2221000000000000'), NeatCardType.mastercard);
      expect(NeatCardType.mastercard.isMastercard, isTrue);
    });

    test('detects JCB, Discover, and Unknown', () {
      expect(NeatCardFormatter.detectCardType('3528000000000000'), NeatCardType.jcb);
      expect(NeatCardType.jcb.isJcb, isTrue);

      expect(NeatCardFormatter.detectCardType('6011000000000000'), NeatCardType.discover);
      expect(NeatCardFormatter.detectCardType('6440000000000000'), NeatCardType.discover);
      expect(NeatCardFormatter.detectCardType('6500000000000000'), NeatCardType.discover);
      expect(NeatCardType.discover.isDiscover, isTrue);

      expect(NeatCardFormatter.detectCardType(''), NeatCardType.unknown);
      expect(NeatCardFormatter.detectCardType('9999000000000000'), NeatCardType.unknown);
      expect(NeatCardType.unknown.isUnknown, isTrue);
    });

    test('getCleanCardNumber strips all non-digits', () {
      expect(NeatCardFormatter.getCleanCardNumber('4111-2222-3333-4444'), '4111222233334444');
      expect(NeatCardFormatter.getCleanCardNumber(' 4111 2222 '), '41112222');
      expect(NeatCardFormatter.getCleanCardNumber(''), '');
    });

    test('handles up to 19 digits for standard cards', () {
      final formatter = NeatInputFormatters.creditCard();
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '6011123456789012345',
        selection: TextSelection.collapsed(offset: 19),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '6011 1234 5678 9012 345');
    });
  });

  group('NeatDateFormatter - Exhaustive Tests', () {
    test('formats ddMMyyyy and parses valid date', () {
      final formatter = NeatInputFormatters.date(
        format: NeatDateFormat.ddMMyyyy,
        separator: '/',
      );

      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '15082026',
        selection: TextSelection.collapsed(offset: 8),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '15/08/2026');
      expect(formatter.getParsedDate(result.text), DateTime(2026, 8, 15));
    });

    test('formats yyyyMMdd with custom dash separator', () {
      final formatter = NeatInputFormatters.date(
        format: NeatDateFormat.yyyyMMdd,
        separator: '-',
      );

      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '20260815',
        selection: TextSelection.collapsed(offset: 8),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '2026-08-15');
      expect(formatter.getParsedDate(result.text), DateTime(2026, 8, 15));
    });

    test('formats mmDdYyyy correctly', () {
      final formatter = NeatInputFormatters.date(
        format: NeatDateFormat.mmDdYyyy,
        separator: '/',
      );

      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '08152026',
        selection: TextSelection.collapsed(offset: 8),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '08/15/2026');
      expect(formatter.getParsedDate(result.text), DateTime(2026, 8, 15));
    });

    test('formats mmYy expiration date format', () {
      final formatter = NeatInputFormatters.date(
        format: NeatDateFormat.mmYy,
        separator: '/',
      );

      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '1229',
        selection: TextSelection.collapsed(offset: 4),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '12/29');
      expect(formatter.getParsedDate(result.text), DateTime(2029, 12, 1));
    });

    test('strict leap year validation in getParsedDate', () {
      final formatter = NeatInputFormatters.date(format: NeatDateFormat.ddMMyyyy);

      // Leap year 2024: Feb 29 is valid
      expect(formatter.getParsedDate('29/02/2024'), DateTime(2024, 2, 29));

      // Non-leap year 2023: Feb 29 is INVALID (must return null, not roll over to March 1)
      expect(formatter.getParsedDate('29/02/2023'), isNull);

      // April 31 does not exist (April has 30 days)
      expect(formatter.getParsedDate('31/04/2025'), isNull);

      // Month > 12 or Day > 31 or Day 00
      expect(formatter.getParsedDate('00/12/2025'), isNull);
      expect(formatter.getParsedDate('15/13/2025'), isNull);
      expect(formatter.getParsedDate('32/01/2025'), isNull);
      expect(formatter.getParsedDate(''), isNull);
      expect(formatter.getParsedDate('12/20'), isNull); // partial
    });
  });

  group('Utility Formatters - Exhaustive Tests', () {
    test('uppercase formatter transforms lowercase text', () {
      final formatter = NeatInputFormatters.uppercase();
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: 'hello_world',
        selection: TextSelection.collapsed(offset: 11),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'HELLO_WORLD');
    });

    test('lowercase formatter transforms uppercase text', () {
      final formatter = NeatInputFormatters.lowercase();
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: 'HELLO_WORLD',
        selection: TextSelection.collapsed(offset: 11),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'hello_world');
    });

    test('latinOnly denies non-ascii characters and accents', () {
      final formatter = NeatInputFormatters.latinOnly();
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: 'nguyễn-văn-a@123',
        selection: TextSelection.collapsed(offset: 16),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'nguynvna123');
    });

    test('noSpaces denies spaces and tabs', () {
      final formatter = NeatInputFormatters.noSpaces();
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: 'hello world test \t\n',
        selection: TextSelection.collapsed(offset: 19),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'helloworldtest');
    });
  });

  group('InputFormatters - Edge Cases & Assertion Tests', () {
    test('NeatCurrencyFormatter throws assertion if thousand and decimal separators are equal', () {
      expect(
        () => NeatCurrencyFormatter(thousandSeparator: '.', decimalSeparator: '.'),
        throwsAssertionError,
      );
    });

    test('NeatCurrencyFormatter cursor navigation inside decimal portion', () {
      final formatter = NeatInputFormatters.currency(
        prefix: r'$',
        allowDecimals: true,
        decimalDigits: 2,
      );

      // User types 10.5 and cursor is after 5
      const oldValue = TextEditingValue(
        text: r'$10.5',
        selection: TextSelection.collapsed(offset: 5),
      );
      const newValue = TextEditingValue(
        text: r'$10.59',
        selection: TextSelection.collapsed(offset: 6),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, r'$10.59');
      expect(result.selection.baseOffset, 6);
    });

    test('NeatCurrencyFormatter handles multiple decimal separators by ignoring extras', () {
      final formatter = NeatInputFormatters.currency(
        prefix: r'$',
        allowDecimals: true,
      );

      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '12.34.56.78',
        selection: TextSelection.collapsed(offset: 11),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, r'$12.34');
    });

    test('NeatCurrencyFormatter empty string format returns empty', () {
      final formatter = NeatInputFormatters.currency();
      expect(
        formatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue.empty,
        ),
        TextEditingValue.empty,
      );
    });

    test('NeatMaskFormatter backspace directly on separator index', () {
      final formatter = NeatInputFormatters.mask('AA-##');
      // oldValue: 'VN-12', cursor at 3 (after -)
      const oldValue = TextEditingValue(
        text: 'VN-12',
        selection: TextSelection.collapsed(offset: 3),
      );
      // User deletes '-' at index 2
      const newValue = TextEditingValue(
        text: 'VN12',
        selection: TextSelection.collapsed(offset: 2),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      // 'V12' with mask 'AA-##' formats 'V' to A, and '12' to ## -> 'V1-2'
      expect(result.text, 'V1-2');
    });

    test('NeatCardFormatter empty string returns empty', () {
      final formatter = NeatInputFormatters.creditCard();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: ''),
      );
      expect(result.text, '');
    });

    test('NeatCardFormatter ignores non-digits and truncates past max limits', () {
      final formatter = NeatInputFormatters.creditCard();
      const oldValue = TextEditingValue.empty;
      // 25 digits
      const newValue = TextEditingValue(
        text: '4111222233334444999999999',
        selection: TextSelection.collapsed(offset: 25),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '4111 2222 3333 4444 999');
    });

    test('NeatDateFormatter parses all formats and handles edge date boundaries', () {
      final ddmm = NeatInputFormatters.date(format: NeatDateFormat.ddMMyyyy);
      final yymm = NeatInputFormatters.date(format: NeatDateFormat.yyyyMMdd, separator: '-');
      final mmdd = NeatInputFormatters.date(format: NeatDateFormat.mmDdYyyy);
      final mmyy = NeatInputFormatters.date(format: NeatDateFormat.mmYy);

      expect(ddmm.getParsedDate('31/01/2025'), DateTime(2025, 1, 31));
      expect(yymm.getParsedDate('2025-01-31'), DateTime(2025, 1, 31));
      expect(mmdd.getParsedDate('01/31/2025'), DateTime(2025, 1, 31));
      expect(mmyy.getParsedDate('01/30'), DateTime(2030, 1, 1));

      // Out of bounds
      expect(ddmm.getParsedDate('32/01/2025'), isNull);
      expect(ddmm.getParsedDate('15/13/2025'), isNull);
      expect(ddmm.getParsedDate('15/00/2025'), isNull);
      expect(ddmm.getParsedDate('00/01/2025'), isNull);
      expect(ddmm.getParsedDate('31/02/2025'), isNull);
      expect(ddmm.getParsedDate('29/02/2023'), isNull); // non-leap
      expect(ddmm.getParsedDate('29/02/2024'), DateTime(2024, 2, 29)); // leap

      // Empty / invalid text
      final emptyRes = ddmm.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: ''),
      );
      expect(emptyRes.text, '');

      // Year > 9999 in parser
      expect(ddmm.getParsedDate('010199999'), isNull);

      // Date typing truncation (> 8 digits)
      final truncatedDate = ddmm.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1508202699999',
          selection: TextSelection.collapsed(offset: 13),
        ),
      );
      expect(truncatedDate.text, '15/08/2026');
    });

    test('Amex truncation beyond 15 digits', () {
      final formatter = NeatInputFormatters.creditCard();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '3412345678901239999',
          selection: TextSelection.collapsed(offset: 19),
        ),
      );
      expect(result.text, '3412 345678 90123');
    });

    test('Currency decimal digits truncation on user input', () {
      final formatter = NeatInputFormatters.currency(
        thousandSeparator: '.',
        decimalSeparator: ',',
        allowDecimals: true,
        decimalDigits: 2,
      );

      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '10,12345',
          selection: TextSelection.collapsed(offset: 8),
        ),
      );
      expect(result.text, '10,12');
      expect(formatter.getNumericValue(result.text), 10.12);
    });
  });
}
