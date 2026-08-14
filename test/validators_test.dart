import 'package:neat_form/neat_form.dart';
import 'package:test/test.dart';

void main() {
  group('NeatValidators.required', () {
    test('returns error for null, empty string, empty list, empty map', () {
      expect(NeatValidators.required(null), isNotNull);
      expect(NeatValidators.required(''), isNotNull);
      expect(NeatValidators.required('   '), isNotNull);
      expect(NeatValidators.required(<dynamic>[]), isNotNull);
      expect(NeatValidators.required(<String, dynamic>{}), isNotNull);
    });

    test('returns null for valid inputs', () {
      expect(NeatValidators.required('hello'), isNull);
      expect(NeatValidators.required(0), isNull);
      expect(NeatValidators.required(false), isNull);
      expect(NeatValidators.required(['item']), isNull);
      expect(NeatValidators.required({'key': 'value'}), isNull);
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

  group('NeatValidators.minLength & maxLength', () {
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

  group('NeatValidators.noSpecialChars & alphanumericOnly', () {
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
  });

  group('NeatValidators.blacklist', () {
    test('flags forbidden words', () {
      final v = NeatValidators.blacklist(['admin', 'root']);
      expect(v('regular_user'), isNull);
      expect(v('super_admin'), isNotNull);
      expect(v('ROOT_ACCESS'), isNotNull);
    });
  });

  group('NeatValidators.combine', () {
    test('runs multiple validators and stops on first error', () {
      final v = NeatValidators.combine<String>([
        NeatValidators.required,
        NeatValidators.minLength(3),
        NeatValidators.alphanumericOnly(),
      ]);

      expect(v(null)?.code, NeatValidators.codeRequired);
      expect(v('ab')?.code, NeatValidators.codeMinLength);
      expect(v('ab!')?.code, NeatValidators.codeAlphanumericOnly);
      expect(v('abc123'), isNull);
    });
  });
}
