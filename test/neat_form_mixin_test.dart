import 'package:neat_form/neat_form.dart';
import 'package:test/test.dart';

enum TestKey { username, age }

class TestFormController with NeatFormMixin<TestKey> {
  Map<TestKey, NeatFieldState<dynamic>> _fields = {
    TestKey.username: const NeatFieldState<String>(value: ''),
    TestKey.age: const NeatFieldState<int?>(value: null),
  };

  @override
  Map<TestKey, NeatFieldState<dynamic>> get fields => _fields;

  @override
  Map<TestKey, NeatValidator<dynamic>> get validators => {
        TestKey.username: NeatValidators.combine([
          NeatValidators.required,
          NeatValidators.minLength(3),
        ]),
        TestKey.age: NeatValidators.combine([
          NeatValidators.required,
          (val) => val is int && val >= 18
              ? null
              : const NeatValidationError.code('underage'),
        ]),
      };

  @override
  void updateStateWithFields(Map<TestKey, NeatFieldState<dynamic>> newFields) {
    _fields = newFields;
  }
}

void main() {
  group('NeatFormMixin', () {
    late TestFormController controller;

    setUp(() {
      controller = TestFormController();
    });

    test('setField updates value and clears error', () {
      controller.setField(TestKey.username, 'dat');
      expect(controller.getField<String>(TestKey.username).value, 'dat');
      expect(controller.getField<String>(TestKey.username).error, isNull);
    });

    test('setAndValidateField runs validator immediately', () {
      final error = controller.setAndValidateField(TestKey.username, 'ab');
      expect(error, isNotNull);
      expect(error?.code, NeatValidators.codeMinLength);
      expect(controller.getField<String>(TestKey.username).isShowError, isTrue);

      final validError = controller.setAndValidateField(TestKey.username, 'abc');
      expect(validError, isNull);
      expect(controller.getField<String>(TestKey.username).isValid, isTrue);
    });

    test('validateForm checks all fields and returns false if any invalid', () {
      final isValidInitial = controller.validateForm();
      expect(isValidInitial, isFalse);
      expect(controller.getField<String>(TestKey.username).showError, isTrue);
      expect(controller.getField<int?>(TestKey.age).showError, isTrue);

      controller.setField(TestKey.username, 'valid_user');
      controller.setField(TestKey.age, 20);

      final isValidFilled = controller.validateForm();
      expect(isValidFilled, isTrue);
    });

    test('validateFieldAsync sets loading state and resolves error', () async {
      Future<NeatValidationError?> asyncCheck(String? val) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (val == 'taken') {
          return const NeatValidationError.code('username_taken');
        }
        return null;
      }

      controller.setField(TestKey.username, 'taken');
      final error = await controller.validateFieldAsync(
        TestKey.username,
        asyncCheck,
      );

      expect(error?.code, 'username_taken');
      expect(controller.getField<String>(TestKey.username).error?.code, 'username_taken');
      expect(controller.getField<String>(TestKey.username).isValidating, isFalse);
    });
  });
}
