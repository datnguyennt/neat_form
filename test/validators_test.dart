import 'package:flutter_test/flutter_test.dart';
import 'package:neat_form/neat_form.dart';

void main() {
  group('NeatValidators.required & requiredWith', () {
    final requiredValidator = NeatValidators.required();

    test('required returns error for null, empty string, empty list, empty map',
        () {
      expect(requiredValidator(null), isNotNull);
      expect(requiredValidator(''), isNotNull);
      expect(requiredValidator('   '), isNotNull);
      expect(requiredValidator(<Object?>[]), isNotNull);
      expect(requiredValidator(<String, Object?>{}), isNotNull);
    });

    test('required returns null for valid inputs', () {
      expect(requiredValidator('hello'), isNull);
      expect(requiredValidator(0), isNull);
      expect(requiredValidator(false), isNull);
      expect(requiredValidator(['item']), isNull);
      expect(requiredValidator({'key': 'value'}), isNull);
    });

    test('required creates configurable required validator', () {
      final customRequired = NeatValidators.required<String>(
        code: 'custom_required',
        message: 'Must not be empty',
      );

      final error = customRequired('');
      expect(error?.code, 'custom_required');
      expect(error?.message, 'Must not be empty');

      expect(customRequired('valid string'), isNull);
    });

    test('requiredWith creates backward compatible required validator', () {
      final customRequired = NeatValidators.requiredWith<String>(
        code: 'custom_required',
        message: 'Must not be empty',
      );

      final error = customRequired('');
      expect(error?.code, 'custom_required');
      expect(error?.message, 'Must not be empty');

      expect(customRequired('valid string'), isNull);
    });
  });

  group('NeatValidators.notBlank & exactLength & lengthRange', () {
    test('notBlank detects spaces, tabs, and newlines', () {
      final v = NeatValidators.notBlank();
      expect(v(''), isNull); // empty handled by required
      expect(v('   '), isNotNull);
      expect(v('\t\n  '), isNotNull);
      expect(v(' valid '), isNull);
      expect(v(123), isNull);
    });

    test('exactLength checks exact character count', () {
      final v = NeatValidators.exactLength(6);
      expect(v('12345'), isNotNull);
      expect(v('123456'), isNull);
      expect(v('1234567'), isNotNull);
      expect(v(null), isNull);
      expect(v(123), isNull);
    });

    test('lengthRange checks bounds', () {
      final v = NeatValidators.lengthRange(3, 6);
      expect(v('ab'), isNotNull);
      expect(v('abc'), isNull);
      expect(v('abcdef'), isNull);
      expect(v('abcdefg'), isNotNull);
      expect(v(null), isNull);
      expect(v(123), isNull);
    });
  });

  group('NeatValidators.email', () {
    test('validates emails and custom regex / pattern', () {
      final defaultEmail = NeatValidators.email();
      expect(defaultEmail('test@example.com'), isNull);
      expect(defaultEmail('invalid_email'), isNotNull);
      expect(defaultEmail(''), isNull);
      expect(defaultEmail(null), isNull);
      expect(defaultEmail(123), isNull);

      // Custom pattern (String as Pattern)
      final patternEmail = NeatValidators.email(customRegex: '@corp.com');
      expect(patternEmail('test@corp.com'), isNull);
      expect(patternEmail('test@other.com'), isNotNull);
    });
  });

  group('NeatValidators.phone', () {
    test('validates standard phone numbers and custom pattern', () {
      final v = NeatValidators.phone();
      expect(v('0912345678'), isNull);
      expect(v('+84912345678'), isNull);
      expect(v('(091) 234-5678'), isNull);
      expect(v('123'), isNotNull);
      expect(v('phone_number'), isNotNull);
      expect(v(''), isNull);
      expect(v(null), isNull);
      expect(v(12345), isNull);

      // Custom pattern (String as Pattern)
      final customV = NeatValidators.phone(customRegex: '090');
      expect(customV('0901234567'), isNull);
      expect(customV('0981234567'), isNotNull);
    });
  });

  group('NeatValidators.startsWith & endsWith & contains & notContains', () {
    test('startsWith and endsWith validate prefixes and suffixes with caseSensitivity', () {
      final startV = NeatValidators.startsWith('SV_');
      expect(startV('SV_12345'), isNull);
      expect(startV('GV_12345'), isNotNull);
      expect(startV(null), isNull);
      expect(startV(123), isNull);

      final startCase = NeatValidators.startsWith('sv_', caseSensitive: false);
      expect(startCase('SV_12345'), isNull);
      expect(startCase('ab_12345'), isNotNull);

      final endV = NeatValidators.endsWith('@gmail.com', caseSensitive: false);
      expect(endV('test@GMAIL.COM'), isNull);
      expect(endV('test@yahoo.com'), isNotNull);
      expect(endV(null), isNull);
      expect(endV(123), isNull);

      final endCase = NeatValidators.endsWith('.PNG', caseSensitive: true);
      expect(endCase('photo.PNG'), isNull);
      expect(endCase('photo.png'), isNotNull);
    });

    test('contains and notContains validate substring presence', () {
      final hasV = NeatValidators.contains('flutter', caseSensitive: false);
      expect(hasV('i love FLUTTER framework'), isNull);
      expect(hasV('i love react'), isNotNull);
      expect(hasV(null), isNull);
      expect(hasV(123), isNull);

      final hasCase = NeatValidators.contains('FLUTTER', caseSensitive: true);
      expect(hasCase('i love FLUTTER'), isNull);
      expect(hasCase('i love flutter'), isNotNull);

      final notV = NeatValidators.notContains('badword', caseSensitive: false);
      expect(notV('hello world'), isNull);
      expect(notV('this has BADWORD inside'), isNotNull);
      expect(notV(null), isNull);
      expect(notV(123), isNull);

      final notCase = NeatValidators.notContains('Admin', caseSensitive: true);
      expect(notCase('admin_user'), isNull);
      expect(notCase('Admin_user'), isNotNull);
    });
  });

  group('NeatValidators.pattern & noSpecialChars', () {
    test('pattern works with RegExp and non-RegExp Pattern', () {
      final regexV = NeatValidators.pattern(RegExp(r'^[A-Z]+$'));
      expect(regexV('ABC'), isNull);
      expect(regexV('abc'), isNotNull);
      expect(regexV(null), isNull);
      expect(regexV(123), isNull);

      final strPatternV = NeatValidators.pattern('secret');
      expect(strPatternV('secret_key'), isNull);
      expect(strPatternV('public_key'), isNotNull);
    });

    test('noSpecialChars works with default and non-RegExp Pattern', () {
      final defaultV = NeatValidators.noSpecialChars();
      expect(defaultV('Hello World'), isNull);
      expect(defaultV('User_123'), isNull);
      expect(defaultV('User@123'), isNotNull);
      expect(defaultV('User!'), isNotNull);
      expect(defaultV(null), isNull);
      expect(defaultV(123), isNull);

      final strPatternV = NeatValidators.noSpecialChars(pattern: '#');
      expect(strPatternV('clean'), isNull);
      expect(strPatternV('dirty#'), isNotNull);
    });
  });

  group('NeatValidators.match & when', () {
    test('match validates equality against target dynamic getter', () {
      var password = 'secretPassword123';
      final v = NeatValidators.match<String>(() => password);

      expect(v('secretPassword123'), isNull);
      expect(v('wrongPassword'), isNotNull);
      expect(v(null), isNull);

      // Mutate password
      password = 'newPassword456';
      expect(v('secretPassword123'), isNotNull);
      expect(v('newPassword456'), isNull);
    });

    test('when conditionally activates validator', () {
      var isCompany = false;
      final taxValidator = NeatValidators.when<String>(
        () => isCompany,
        NeatValidators.required(message: 'Tax code required for company'),
      );

      expect(taxValidator(''), isNull); // isCompany is false -> bypassed

      isCompany = true;
      expect(taxValidator(''), isNotNull);
      expect(taxValidator('TAX123'), isNull);
    });
  });

  group('NeatValidators.passwordStrength & creditCard', () {
    test('passwordStrength validates character classes', () {
      final v = NeatValidators.passwordStrength();
      expect(v('Aa1!xxxx'), isNull);
      expect(v('password'), isNotNull); // no upper, digit, special
      expect(v('PASSWORD123'), isNotNull); // no lower, special
      expect(v('Pass123'), isNotNull); // no special
      expect(v(null), isNull);
      expect(v(123), isNull);
    });

    test('creditCard validates Luhn checksum', () {
      final v = NeatValidators.creditCard();
      // Valid Visa
      expect(v('4532 0151 1283 0366'), isNull);
      // Invalid Luhn
      expect(v('4532 0151 1283 0367'), isNotNull);
      // Too short
      expect(v('12345'), isNotNull);
      // Non-digits
      expect(v('4532-0151-1283-036a'), isNotNull);
      expect(v(null), isNull);
      expect(v(123), isNull);
    });
  });

  group('NeatValidators.alphanumericOnly & spaces & latinOnly & noEmoji & noHtml', () {
    test('alphanumericOnly allows only letters and digits', () {
      final v = NeatValidators.alphanumericOnly();
      expect(v('User123'), isNull);
      expect(v('User 123'), isNotNull);
      expect(v('User_123'), isNotNull);
      expect(v(null), isNull);
      expect(v(123), isNull);
    });

    test('noSpaces flags spaces anywhere', () {
      final v = NeatValidators.noSpaces();
      expect(v('no_spaces'), isNull);
      expect(v('has space'), isNotNull);
      expect(v(null), isNull);
      expect(v(123), isNull);
    });

    test('noLeadingTrailingSpaces flags outer whitespace only', () {
      final v = NeatValidators.noLeadingTrailingSpaces();
      expect(v('hello world'), isNull);
      expect(v(' hello world'), isNotNull);
      expect(v('hello world '), isNotNull);
      expect(v(null), isNull);
      expect(v(123), isNull);
    });

    test('latinOnly and noEmoji and noHtml', () {
      final latinV = NeatValidators.latinOnly();
      expect(latinV('Hello World'), isNull);
      expect(latinV('Xin chào'), isNotNull);
      expect(latinV(null), isNull);
      expect(latinV(123), isNull);

      final emojiV = NeatValidators.noEmoji();
      expect(emojiV('Hello'), isNull);
      expect(emojiV('Hello 😀'), isNotNull);
      expect(emojiV(null), isNull);
      expect(emojiV(123), isNull);

      final htmlV = NeatValidators.noHtml();
      expect(htmlV('Clean text'), isNull);
      expect(htmlV('<script>alert("xss")</script>'), isNotNull);
      expect(htmlV('<b>Bold</b>'), isNotNull);
      expect(htmlV(null), isNull);
      expect(htmlV(123), isNull);
    });
  });

  group('NeatValidators.blacklist', () {
    test('blacklist flags forbidden words', () {
      final v = NeatValidators.blacklist(['admin', 'root']);
      expect(v('regular_user'), isNull);
      expect(v('super_admin'), isNotNull);
      expect(v('ROOT_ACCESS'), isNotNull);
      expect(v(null), isNull);
      expect(v(123), isNull);
    });
  });

  group('NeatValidators.booleans and items', () {
    test('mustBeTrue and mustBeFalse', () {
      final trueV = NeatValidators.mustBeTrue();
      expect(trueV(true), isNull);
      expect(trueV(false), isNotNull);
      expect(trueV(null), isNotNull);
      expect(trueV('true'), isNotNull);

      final falseV = NeatValidators.mustBeFalse();
      expect(falseV(false), isNull);
      expect(falseV(true), isNotNull);
      expect(falseV(null), isNotNull);
      expect(falseV('false'), isNotNull);
    });

    test('minItems, maxItems, and uniqueItems for iterables', () {
      final minV = NeatValidators.minItems(2);
      expect(minV([1, 2]), isNull);
      expect(minV([1]), isNotNull);
      expect(minV(null), isNull);
      expect(minV('not_iterable'), isNull);

      final maxV = NeatValidators.maxItems(2);
      expect(maxV([1, 2]), isNull);
      expect(maxV([1, 2, 3]), isNotNull);
      expect(maxV(null), isNull);
      expect(maxV('not_iterable'), isNull);

      final uniqV = NeatValidators.uniqueItems();
      expect(uniqV([1, 2, 3]), isNull);
      expect(uniqV([1, 2, 1]), isNotNull);
      expect(uniqV(null), isNull);
      expect(uniqV('not_iterable'), isNull);
    });
  });

  group('NeatValidators.numbers and ranges', () {
    test('minValue, maxValue, positive, negative, multipleOf, decimalPrecision, numeric, url', () {
      final minV = NeatValidators.minValue(10);
      expect(minV(15), isNull);
      expect(minV(10), isNull);
      expect(minV(9), isNotNull);
      expect(minV(null), isNull);
      expect(minV('non_num'), isNull);

      final maxV = NeatValidators.maxValue(100);
      expect(maxV(50), isNull);
      expect(maxV(100), isNull);
      expect(maxV(101), isNotNull);
      expect(maxV(null), isNull);
      expect(maxV('non_num'), isNull);

      final posV = NeatValidators.positive();
      expect(posV(5), isNull);
      expect(posV(0), isNotNull);
      expect(posV(-1), isNotNull);
      expect(posV(null), isNull);
      expect(posV('abc'), isNull);

      final negV = NeatValidators.negative();
      expect(negV(-5), isNull);
      expect(negV(0), isNotNull);
      expect(negV(5), isNotNull);
      expect(negV(null), isNull);
      expect(negV('abc'), isNull);

      final multV = NeatValidators.multipleOf(5);
      expect(multV(10), isNull);
      expect(multV(12), isNotNull);
      expect(multV(null), isNull);
      expect(multV('abc'), isNull);

      final precV = NeatValidators.decimalPrecision(2);
      expect(precV('12.34'), isNull);
      expect(precV('12.345'), isNotNull);
      expect(precV(null), isNull);
      expect(precV(123), isNull);

      final numV = NeatValidators.numeric();
      expect(numV('12345'), isNull);
      expect(numV('-123.45'), isNull);
      expect(numV('abc'), isNotNull);
      expect(numV(null), isNull);
      expect(numV(123), isNull);

      final urlV = NeatValidators.url();
      expect(urlV('https://flutter.dev'), isNull);
      expect(urlV('not_a_url'), isNotNull);
      expect(urlV(null), isNull);
      expect(urlV(123), isNull);
    });
  });

  group('NeatValidators.dates', () {
    test('pastDate, futureDate, dateRange', () {
      final pastV = NeatValidators.pastDate();
      expect(pastV(DateTime.now().subtract(const Duration(days: 1))), isNull);
      expect(pastV(DateTime.now().add(const Duration(days: 1))), isNotNull);
      expect(pastV(null), isNull);
      expect(pastV('not_date'), isNull);

      final futV = NeatValidators.futureDate();
      expect(futV(DateTime.now().add(const Duration(days: 1))), isNull);
      expect(futV(DateTime.now().subtract(const Duration(days: 1))), isNotNull);
      expect(futV(null), isNull);
      expect(futV('not_date'), isNull);

      final rangeV = NeatValidators.dateRange(
        DateTime(2020, 1, 1),
        DateTime(2030, 1, 1),
      );
      expect(rangeV(DateTime(2025, 1, 1)), isNull);
      expect(rangeV(DateTime(2019, 1, 1)), isNotNull);
      expect(rangeV(DateTime(2031, 1, 1)), isNotNull);
      expect(rangeV(null), isNull);
      expect(rangeV('not_date'), isNull);
    });
  });

  group('NeatValidators.custom & combine', () {
    test('custom validator evaluates predicate correctly', () {
      final v = NeatValidators.custom<int>(
        (val) => val != null && val % 2 == 0,
        code: 'must_be_even',
      );
      expect(v(4), isNull);
      expect(v(5)?.code, 'must_be_even');
    });

    test('combine runs multiple validators and stops on first error', () {
      final v = NeatValidators.combine<String>([
        NeatValidators.required(),
        NeatValidators.minLength(3),
        NeatValidators.alphanumericOnly(),
      ]);

      expect(v(null)?.code, NeatValidators.codeRequired);
      expect(v('ab')?.code, NeatValidators.codeMinLength);
      expect(v('ab!')?.code, NeatValidators.codeAlphanumericOnly);
      expect(v('abc123'), isNull);
    });
  });

  group('NeatValidationError equality & formatting', () {
    test('equality and hashCode works with same codes and params', () {
      const e1 = NeatValidationError('code1', params: {'a': 1});
      const e2 = NeatValidationError('code1', params: {'a': 1});
      const e3 = NeatValidationError('code1', params: {'a': 2});

      expect(e1, equals(e2));
      expect(e1.hashCode, equals(e2.hashCode));
      expect(e1, isNot(equals(e3)));
    });

    test('toString formats error correctly', () {
      const e = NeatValidationError(
        'err_code',
        params: {'k': 'v'},
        message: 'My error',
      );
      expect(e.toString(), contains('err_code'));
      expect(e.toString(), contains('My error'));
    });
  });

  group('NeatValidators.dateString tests', () {
    test('validates standard DD/MM/YYYY calendar dates', () {
      final v = NeatValidators.dateString(format: 'DD/MM/YYYY');
      expect(v('15/08/1995'), isNull);
      expect(v('31/12/2020'), isNull);
      expect(v('29/02/2024'), isNull); // Leap year 2024
      expect(v(null), isNull);
      expect(v(''), isNull);

      // Invalid dates
      expect(v('45/64/5645')?.code, NeatValidators.codeDateString);
      expect(v('32/01/2020')?.code, NeatValidators.codeDateString);
      expect(v('15/13/2020')?.code, NeatValidators.codeDateString);
      expect(v('29/02/2023')?.code, NeatValidators.codeDateString); // Not leap year
      expect(v('invalid-string')?.code, NeatValidators.codeDateString);
      expect(v('15/08/95')?.code, NeatValidators.codeDateString); // Format mismatch
    });

    test('validates alternative formats: YYYY-MM-DD and MM/DD/YYYY', () {
      final vYmd = NeatValidators.dateString(format: 'YYYY-MM-DD');
      expect(vYmd('1995-08-15'), isNull);
      expect(vYmd('2020-02-29'), isNull);
      expect(vYmd('2020-13-15')?.code, NeatValidators.codeDateString);

      final vMdy = NeatValidators.dateString(format: 'MM/DD/YYYY');
      expect(vMdy('08/15/1995'), isNull);
      expect(vMdy('13/15/1995')?.code, NeatValidators.codeDateString);
    });

    test('validates mustBePast, mustBeFuture, minYear, maxYear', () {
      final vPast = NeatValidators.dateString(
        format: 'DD/MM/YYYY',
        mustBePast: true,
        minYear: 1900,
        maxYear: 2025,
      );
      expect(vPast('01/01/2000'), isNull);
      expect(vPast('01/01/2099')?.code, NeatValidators.codeDateString);
      expect(vPast('01/01/1850')?.code, NeatValidators.codeDateString);
      expect(vPast('01/01/2030')?.code, NeatValidators.codeDateString);

      final vFuture = NeatValidators.dateString(
        format: 'DD/MM/YYYY',
        mustBeFuture: true,
      );
      expect(vFuture('01/01/2099'), isNull);
      expect(vFuture('01/01/1990')?.code, NeatValidators.codeDateString);
    });
  });
}
