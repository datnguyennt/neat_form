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
      expect(requiredValidator(<dynamic>[]), isNotNull);
      expect(requiredValidator(<String, dynamic>{}), isNotNull);
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
