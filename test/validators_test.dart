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

  group('NeatValidators.notBlank & exactLength', () {
    test('notBlank detects spaces, tabs, and newlines', () {
      final v = NeatValidators.notBlank();
      expect(v(''), isNull); // empty handled by required
      expect(v('   '), isNotNull);
      expect(v('\t\n  '), isNotNull);
      expect(v(' valid '), isNull);
    });

    test('exactLength checks exact character count', () {
      final v = NeatValidators.exactLength(6);
      expect(v('12345'), isNotNull);
      expect(v('123456'), isNull);
      expect(v('1234567'), isNotNull);
      expect(v(null), isNull);
    });
  });

  group('NeatValidators.phone', () {
    test('validates standard phone numbers with or without +', () {
      final v = NeatValidators.phone();
      expect(v('0912345678'), isNull);
      expect(v('+84912345678'), isNull);
      expect(v('(091) 234-5678'), isNull);
      expect(v('123'), isNotNull); // too short
      expect(v('phone_number'), isNotNull);
    });
  });

  group('NeatValidators.startsWith & endsWith & contains & notContains', () {
    test('startsWith and endsWith validate prefixes and suffixes', () {
      final startV = NeatValidators.startsWith('SV_');
      expect(startV('SV_12345'), isNull);
      expect(startV('GV_12345'), isNotNull);

      final endV = NeatValidators.endsWith('@gmail.com', caseSensitive: false);
      expect(endV('test@GMAIL.COM'), isNull);
      expect(endV('test@yahoo.com'), isNotNull);
    });

    test('contains and notContains validate substring presence', () {
      final hasV = NeatValidators.contains('flutter');
      expect(hasV('i love flutter framework'), isNull);
      expect(hasV('i love react'), isNotNull);

      final notV = NeatValidators.notContains('badword');
      expect(notV('hello world'), isNull);
      expect(notV('this has badword inside'), isNotNull);
    });
  });

  group('NeatValidators.latinOnly & noEmoji & noHtml', () {
    test('latinOnly restricts to English alphabet and spaces', () {
      final v = NeatValidators.latinOnly();
      expect(v('NGUYEN VAN A'), isNull);
      expect(v('John Doe'), isNull);
      expect(v('Nguyễn Văn A'), isNotNull); // Vietnamese accented characters
      expect(v('User123'), isNotNull);
    });

    test('noEmoji flags common emojis', () {
      final v = NeatValidators.noEmoji();
      expect(v('Standard text'), isNull);
      expect(v('Text with 😀 smile'), isNotNull);
      expect(v('🔥 fire'), isNotNull);
    });

    test('noHtml flags HTML tags', () {
      final v = NeatValidators.noHtml();
      expect(v('Normal description'), isNull);
      expect(v('<script>alert("xss")</script>'), isNotNull);
      expect(v('Hello <b>world</b>'), isNotNull);
    });
  });

  group('NeatValidators.passwordStrength', () {
    test('validates password criteria', () {
      final v = NeatValidators.passwordStrength(
        minUppercase: 1,
        minLowercase: 1,
        minDigits: 1,
        minSpecialChars: 1,
      );

      expect(v('P@ssword1'), isNull);
      expect(v('password1'), isNotNull); // missing uppercase & special
      expect(v('PASSWORD!'), isNotNull); // missing lowercase & digits
      expect(v('PassWord!'), isNotNull); // missing digit
    });
  });

  group('NeatValidators.creditCard', () {
    test('validates credit card numbers using Luhn check', () {
      final v = NeatValidators.creditCard();
      // Valid test Visa card
      expect(v('4532 0151 1283 0366'), isNull);
      // Valid test Mastercard
      expect(v('5425-2334-3010-9903'), isNull);
      // Invalid numbers
      expect(v('4532015112830367'), isNotNull);
      expect(v('12345'), isNotNull);
    });
  });

  group('NeatValidators.positive & negative & multipleOf & decimalPrecision', () {
    test('positive and negative check number sign', () {
      final pos = NeatValidators.positive();
      expect(pos(10), isNull);
      expect(pos(0.1), isNull);
      expect(pos(0), isNotNull);
      expect(pos(-5), isNotNull);

      final neg = NeatValidators.negative();
      expect(neg(-1), isNull);
      expect(neg(0), isNotNull);
      expect(neg(5), isNotNull);
    });

    test('multipleOf checks step divisibility', () {
      final v = NeatValidators.multipleOf(10000);
      expect(v(50000), isNull);
      expect(v(10000), isNull);
      expect(v(25000), isNotNull);
    });

    test('decimalPrecision checks maximum decimals allowed', () {
      final v = NeatValidators.decimalPrecision(2);
      expect(v(100), isNull);
      expect(v(100.5), isNull);
      expect(v(100.25), isNull);
      expect(v(100.125), isNotNull);
      expect(v('19.99'), isNull);
      expect(v('19.999'), isNotNull);
    });
  });

  group('NeatValidators.pastDate & futureDate & dateRange', () {
    test('pastDate and futureDate evaluate relative to now', () {
      final pastV = NeatValidators.pastDate();
      expect(pastV(DateTime.now().subtract(const Duration(days: 1))), isNull);
      expect(pastV(DateTime.now().add(const Duration(days: 1))), isNotNull);

      final futureV = NeatValidators.futureDate();
      expect(futureV(DateTime.now().add(const Duration(days: 1))), isNull);
      expect(futureV(DateTime.now().subtract(const Duration(days: 1))), isNotNull);
    });

    test('dateRange checks bounds', () {
      final min = DateTime(2026, 1, 1);
      final max = DateTime(2026, 12, 31);
      final v = NeatValidators.dateRange(min, max);

      expect(v(DateTime(2026, 6, 15)), isNull);
      expect(v(DateTime(2025, 12, 31)), isNotNull);
      expect(v(DateTime(2027, 1, 1)), isNotNull);
    });
  });

  group('NeatValidators.mustBeTrue & mustBeFalse', () {
    test('mustBeTrue and mustBeFalse validate booleans', () {
      final trueV = NeatValidators.mustBeTrue();
      expect(trueV(true), isNull);
      expect(trueV(false), isNotNull);
      expect(trueV(null), isNotNull);

      final falseV = NeatValidators.mustBeFalse();
      expect(falseV(false), isNull);
      expect(falseV(true), isNotNull);
      expect(falseV(null), isNotNull);
    });
  });

  group('NeatValidators.minItems & maxItems & uniqueItems', () {
    test('minItems and maxItems check collection size', () {
      final minV = NeatValidators.minItems(2);
      expect(minV(['a', 'b']), isNull);
      expect(minV(['a']), isNotNull);

      final maxV = NeatValidators.maxItems(3);
      expect(maxV([1, 2, 3]), isNull);
      expect(maxV([1, 2, 3, 4]), isNotNull);
    });

    test('uniqueItems checks for duplicates in list', () {
      final v = NeatValidators.uniqueItems();
      expect(v(['a@b.com', 'c@d.com']), isNull);
      expect(v(['a@b.com', 'a@b.com']), isNotNull);
    });
  });

  group('NeatValidators.when', () {
    test('runs validator only when condition is true', () {
      var isUSResident = false;
      final validator = NeatValidators.when<String>(
        () => isUSResident,
        NeatValidators.required(code: 'us_zip_required'),
      );

      // When condition is false, empty string is valid
      expect(validator(''), isNull);

      // When condition is true, validator runs
      isUSResident = true;
      expect(validator('')?.code, 'us_zip_required');
      expect(validator('90210'), isNull);
    });
  });

  group('NeatValidators.email', () {
    final emailValidator = NeatValidators.email();

    test('validates correct email formats', () {
      expect(emailValidator('test@example.com'), isNull);
      expect(emailValidator('user.name+tag@sub.domain.co'), isNull);
      expect(emailValidator(''), isNull); // Empty strings handled by required
      expect(emailValidator(null), isNull);
    });

    test('flags invalid email formats', () {
      expect(emailValidator('plainaddress'), isNotNull);
      expect(emailValidator('missing@domain'), isNotNull);
      expect(emailValidator('@missingusername.com'), isNotNull);
      expect(emailValidator('missing.at.symbol.com'), isNotNull);
    });
  });

  group('NeatValidators.numeric & url', () {
    test('numeric validates integers and decimals', () {
      final v = NeatValidators.numeric();
      expect(v('123'), isNull);
      expect(v('-45.67'), isNull);
      expect(v('0'), isNull);
      expect(v('abc'), isNotNull);
      expect(v('12a3'), isNotNull);
      expect(v(''), isNull); // empty string ignored
      expect(v(null), isNull);
    });

    test('url validates correct http/https urls', () {
      final v = NeatValidators.url();
      expect(v('https://example.com'), isNull);
      expect(v('http://sub.domain.com/path?arg=1'), isNull);
      expect(v('ftp://example.com'), isNotNull);
      expect(v('not_a_url'), isNotNull);
      expect(v(''), isNull);
      expect(v(null), isNull);
    });
  });

  group('NeatValidators.minLength & maxLength & lengthRange', () {
    test('minLength works correctly', () {
      final v = NeatValidators.minLength(5);
      expect(v('1234'), isNotNull);
      expect(v('12345'), isNull);
      expect(v('123456'), isNull);
      expect(v(null), isNull);
    });

    test('maxLength works correctly', () {
      final v = NeatValidators.maxLength(5);
      expect(v('1234'), isNull);
      expect(v('12345'), isNull);
      expect(v('123456'), isNotNull);
      expect(v(null), isNull);
    });

    test('lengthRange validates both min and max', () {
      final v = NeatValidators.lengthRange(3, 6);
      expect(v('ab'), isNotNull);
      expect(v('abc'), isNull);
      expect(v('abcdef'), isNull);
      expect(v('abcdefg'), isNotNull);
    });
  });

  group('NeatValidators.minValue & maxValue', () {
    test('minValue works correctly', () {
      final v = NeatValidators.minValue(18);
      expect(v(17), isNotNull);
      expect(v(18), isNull);
      expect(v(19), isNull);
    });

    test('maxValue works correctly', () {
      final v = NeatValidators.maxValue(100);
      expect(v(99), isNull);
      expect(v(100), isNull);
      expect(v(101), isNotNull);
    });
  });

  group('NeatValidators.match', () {
    test('validates equality against a dynamic target getter', () {
      var password = 'secretPassword123';
      final v = NeatValidators.match<String>(() => password);

      expect(v('secretPassword123'), isNull);
      expect(v('wrongPassword'), isNotNull);

      // Mutate password
      password = 'newPassword456';
      expect(v('secretPassword123'), isNotNull);
      expect(v('newPassword456'), isNull);
    });
  });

  group('NeatValidators.noSpecialChars & alphanumericOnly & spaces', () {
    test('noSpecialChars flags symbols', () {
      final v = NeatValidators.noSpecialChars();
      expect(v('Hello World'), isNull);
      expect(v('User_123'), isNull);
      expect(v('User@123'), isNotNull);
      expect(v('User!'), isNotNull);
    });

    test('alphanumericOnly allows only letters and digits', () {
      final v = NeatValidators.alphanumericOnly();
      expect(v('User123'), isNull);
      expect(v('User 123'), isNotNull);
      expect(v('User_123'), isNotNull);
    });

    test('noSpaces flags spaces anywhere', () {
      final v = NeatValidators.noSpaces();
      expect(v('no_spaces'), isNull);
      expect(v('has space'), isNotNull);
    });

    test('noLeadingTrailingSpaces flags outer whitespace only', () {
      final v = NeatValidators.noLeadingTrailingSpaces();
      expect(v('hello world'), isNull);
      expect(v(' hello world'), isNotNull);
      expect(v('hello world '), isNotNull);
    });
  });

  group('NeatValidators.blacklist', () {
    test('flags forbidden words', () {
      final v = NeatValidators.blacklist(['admin', 'root']);
      expect(v('regular_user'), isNull);
      expect(v('super_admin'), isNotNull);
      expect(v('ROOT_ACCESS'), isNotNull);
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
}
