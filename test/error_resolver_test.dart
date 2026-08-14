import 'package:flutter_test/flutter_test.dart';
import 'package:neat_form/neat_form.dart';

void main() {
  group('NeatErrorResolver', () {
    test('resolves registered code using custom handler', () {
      final resolver = NeatErrorResolver<String>();
      resolver.register(
        NeatValidators.codeMinLength,
        (context, params, fieldName) =>
            '${fieldName ?? "Field"} must have at least ${params["minLength"]} chars in $context',
      );

      const error = NeatValidationError(
        NeatValidators.codeMinLength,
        params: {'minLength': 8},
      );

      final message = resolver.resolve(
        'en_US',
        error,
        fieldName: 'Password',
      );

      expect(message, 'Password must have at least 8 chars in en_US');
    });

    test('falls back to fallback resolver if code not registered', () {
      final resolver = NeatErrorResolver<String>(
        fallbackResolver: (context, error, {fieldName}) =>
            'Custom fallback for ${error.code} in $context',
      );

      const error = NeatValidationError.code('unknown_code');
      final message = resolver.resolve('fr_FR', error);

      expect(message, 'Custom fallback for unknown_code in fr_FR');
    });

    test('interpolates params in error message when no handler registered', () {
      final resolver = NeatErrorResolver<String>();

      const error = NeatValidationError(
        NeatValidators.codeMinLength,
        params: {'minLength': 8},
        message: 'Must be at least {minLength} characters',
      );

      final message = resolver.resolve('en', error);
      expect(message, 'Must be at least 8 characters');
    });

    test('falls back to error message or error code if no fallback resolver',
        () {
      final resolver = NeatErrorResolver<String>();

      const errorWithMessage = NeatValidationError(
        'custom_code',
        message: 'Explicit fallback message',
      );
      expect(
        resolver.resolve('en', errorWithMessage),
        'Explicit fallback message',
      );

      const errorWithoutMessage = NeatValidationError.code('code_only');
      expect(
        resolver.resolve('en', errorWithoutMessage),
        'code_only',
      );
    });

    test('fallbackResolver property updates the fallback resolver', () {
      final resolver = NeatErrorResolver<String>()
        ..fallbackResolver =
            (context, error, {fieldName}) => 'New fallback: ${error.code}';

      const error = NeatValidationError.code('some_code');
      expect(resolver.resolve('en', error), 'New fallback: some_code');
    });
  });

  group('NeatValidationError equality & hashCode', () {
    test('equals and hashCode match even when params map key order differs',
        () {
      const err1 = NeatValidationError(
        'test',
        params: {'b': 2, 'a': 1},
      );
      const err2 = NeatValidationError(
        'test',
        params: {'a': 1, 'b': 2},
      );

      expect(err1, equals(err2));
      expect(err1.hashCode, equals(err2.hashCode));
    });

    test('deep equality check for nested maps and lists in params', () {
      const err1 = NeatValidationError(
        'test',
        params: {
          'roles': ['admin', 'user'],
          'config': {'active': true},
        },
      );
      const err2 = NeatValidationError(
        'test',
        params: {
          'roles': ['admin', 'user'],
          'config': {'active': true},
        },
      );

      expect(err1, equals(err2));
      expect(err1.hashCode, equals(err2.hashCode));
    });
  });
}
