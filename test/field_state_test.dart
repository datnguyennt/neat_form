import 'package:flutter_test/flutter_test.dart';
import 'package:neat_form/neat_form.dart';

void main() {
  group('NeatSubmissionStatus', () {
    test('enum boolean getters work correctly', () {
      expect(NeatSubmissionStatus.idle.isIdle, isTrue);
      expect(NeatSubmissionStatus.idle.isSubmitting, isFalse);
      expect(NeatSubmissionStatus.idle.isSuccess, isFalse);
      expect(NeatSubmissionStatus.idle.isFailure, isFalse);

      expect(NeatSubmissionStatus.submitting.isSubmitting, isTrue);
      expect(NeatSubmissionStatus.submitting.isIdle, isFalse);

      expect(NeatSubmissionStatus.success.isSuccess, isTrue);
      expect(NeatSubmissionStatus.success.isIdle, isFalse);

      expect(NeatSubmissionStatus.failure.isFailure, isTrue);
      expect(NeatSubmissionStatus.failure.isIdle, isFalse);
    });
  });

  group('NeatValidationError deep equality and hashing edge cases', () {
    test('convenience constructor code only', () {
      const err = NeatValidationError.code('required');
      expect(err.code, 'required');
      expect(err.params, isEmpty);
      expect(err.message, isNull);
      expect(err.toString(), contains('required'));
    });

    test('deep equality handles maps and lists with differing keys or lengths', () {
      const err1 = NeatValidationError(
        'code',
        params: {'a': 1, 'b': 2},
      );
      const errDifferentKeys = NeatValidationError(
        'code',
        params: {'a': 1, 'c': 2},
      );
      const errDifferentLength = NeatValidationError(
        'code',
        params: {'a': 1},
      );

      expect(err1 == errDifferentKeys, isFalse);
      expect(err1 == errDifferentLength, isFalse);
      expect(err1 == Object(), isFalse);
    });

    test('deep equality with nested iterables and maps of different contents', () {
      const errA = NeatValidationError('test', params: {
        'list': [1, 2, 3],
        'nested': {'x': 10},
      });
      const errB = NeatValidationError('test', params: {
        'list': [1, 2, 4],
        'nested': {'x': 10},
      });
      const errC = NeatValidationError('test', params: {
        'list': [1, 2],
        'nested': {'x': 10},
      });
      const errD = NeatValidationError('test', params: {
        'list': [1, 2, 3],
        'nested': {'x': 20},
      });

      expect(errA == errB, isFalse);
      expect(errA == errC, isFalse);
      expect(errA == errD, isFalse);
    });
  });

  group('NeatFieldState', () {
    test('lifecycle flags and status calculation', () {
      const state = NeatFieldState<String>(
        value: '',
      );

      expect(state.isValid, isTrue);
      expect(state.isInvalid, isFalse);
      expect(state.isEmpty, isTrue);
      expect(state.isNotEmpty, isFalse);
      expect(state.isDirty, isFalse);
      expect(state.isErrorVisible, isFalse);
      expect(state.isShowError, isFalse);
      expect(state.toString(), contains('NeatFieldState'));
    });

    test('isDirty calculation when value changes', () {
      const state = NeatFieldState<String>(
        value: 'new_value',
        initialValue: 'old_value',
      );

      expect(state.isDirty, isTrue);
    });

    test('isDirty works correctly when initialValue is null and changed', () {
      const state = NeatFieldState<int?>(
        value: null,
      );
      expect(state.isDirty, isFalse);

      final updated = state.copyWith(value: 42);
      expect(updated.isDirty, isTrue);
    });

    test('initialValue defaults to value when omitted in constructor', () {
      const state = NeatFieldState<String>(value: 'default_val');
      expect(state.initialValue, 'default_val');
      expect(state.isDirty, isFalse);

      final updated = state.copyWith(value: 'new_val');
      expect(updated.initialValue, 'default_val');
      expect(updated.isDirty, isTrue);
    });

    test('explicit initialValue as null with non-null value', () {
      const state = NeatFieldState<String?>(
        value: 'hello',
        initialValue: null,
      );
      expect(state.value, 'hello');
      expect(state.initialValue, isNull);
      expect(state.isDirty, isTrue);
    });

    test(
        'isErrorVisible is true only when showError flag is true AND field is invalid',
        () {
      const validWithErrorHidden = NeatFieldState<String>(
        value: 'abc',
        error: NeatValidationError.code('error'),
      );
      expect(validWithErrorHidden.isErrorVisible, isFalse);
      expect(validWithErrorHidden.isShowError, isFalse);

      const invalidWithErrorShown = NeatFieldState<String>(
        value: 'abc',
        error: NeatValidationError.code('error'),
        showError: true,
      );
      expect(invalidWithErrorShown.isErrorVisible, isTrue);
      expect(invalidWithErrorShown.isShowError, isTrue);
    });

    test('isEmpty handles String, Iterable, Map, null correctly', () {
      expect(const NeatFieldState<String>(value: '').isEmpty, isTrue);
      expect(const NeatFieldState<String>(value: '   ').isEmpty, isTrue);
      expect(const NeatFieldState<List<int>>(value: []).isEmpty, isTrue);
      expect(const NeatFieldState<Map<String, int>>(value: {}).isEmpty, isTrue);
      expect(const NeatFieldState<String?>(value: null).isEmpty, isTrue);
      expect(const NeatFieldState<int>(value: 0).isEmpty, isFalse);
      expect(const NeatFieldState<bool>(value: false).isEmpty, isFalse);
    });

    test('copyWith updates state correctly and supports copying null values',
        () {
      const initial = NeatFieldState<String?>(
        value: 'hello',
        error: NeatValidationError.code('err'),
        initialValue: 'hello',
      );

      final updated = initial.copyWith(
        value: 'world',
        showError: true,
        isTouched: true,
        isOptional: true,
        isValidating: true,
        isValidated: true,
        error: const NeatValidationError.code('test_error'),
      );

      expect(updated.value, 'world');
      expect(updated.showError, isTrue);
      expect(updated.isTouched, isTrue);
      expect(updated.isOptional, isTrue);
      expect(updated.isValidating, isTrue);
      expect(updated.isValidated, isTrue);
      expect(updated.error?.code, 'test_error');

      // Copy with nulls directly
      final resetNulls = updated.copyWith(
        value: null,
        error: null,
        initialValue: null,
      );

      expect(resetNulls.value, isNull);
      expect(resetNulls.error, isNull);
      expect(resetNulls.initialValue, isNull);
    });

    test('equality and hashCode comparison across all properties', () {
      const base = NeatFieldState<String>(
        value: 'a',
        error: null,
        showError: false,
        isTouched: false,
        isOptional: false,
        isValidating: false,
        isValidated: false,
        initialValue: 'a',
      );
      const clone = NeatFieldState<String>(
        value: 'a',
        error: null,
        showError: false,
        isTouched: false,
        isOptional: false,
        isValidating: false,
        isValidated: false,
        initialValue: 'a',
      );

      expect(base, equals(clone));
      expect(base.hashCode, equals(clone.hashCode));
      expect(base == Object(), isFalse);

      expect(base == base.copyWith(value: 'b'), isFalse);
      expect(base == base.copyWith(error: const NeatValidationError.code('e')), isFalse);
      expect(base == base.copyWith(showError: true), isFalse);
      expect(base == base.copyWith(isTouched: true), isFalse);
      expect(base == base.copyWith(isOptional: true), isFalse);
      expect(base == base.copyWith(isValidating: true), isFalse);
      expect(base == base.copyWith(isValidated: true), isFalse);
      expect(base == base.copyWith(initialValue: 'other'), isFalse);
    });
  });

  group('NeatFormFieldMapExtension', () {
    test('isFilledAndValid and areAllFieldsValid evaluate correctly', () {
      final map = <String, NeatFieldState<Object?>>{
        'email': const NeatFieldState<String>(value: 'test@example.com'),
        'password': const NeatFieldState<String>(value: '12345678'),
        'nickname': const NeatFieldState<String>(value: '', isOptional: true),
      };

      expect(map.isFilledAndValid('email'), isTrue);
      expect(map.isFilledAndValid('password'), isTrue);
      expect(
        map.isFilledAndValid('nickname'),
        isTrue,
      );
      expect(map.areAllFieldsValid, isTrue);
      expect(map.isAllFieldsValid, isTrue);
    });

    test('areAllFieldsValid returns false if a required field is empty', () {
      final map = <String, NeatFieldState<Object?>>{
        'email': const NeatFieldState<String>(value: ''),
        'password': const NeatFieldState<String>(value: '12345678'),
      };

      expect(map.isFilledAndValid('email'), isFalse);
      expect(map.areAllFieldsValid, isFalse);
      expect(map.isAllFieldsValid, isFalse);
    });

    test('toValuesMap extracts raw values', () {
      final map = <String, NeatFieldState<Object?>>{
        'email': const NeatFieldState<String>(value: 'a@b.com'),
        'age': const NeatFieldState<int>(value: 25),
      };

      final values = map.toValuesMap();
      expect(values, {'email': 'a@b.com', 'age': 25});
    });

    test('isDirty detects if any field is modified', () {
      final cleanMap = <String, NeatFieldState<Object?>>{
        'name': const NeatFieldState<String>(value: 'John', initialValue: 'John'),
      };
      expect(cleanMap.isDirty, isFalse);

      final dirtyMap = <String, NeatFieldState<Object?>>{
        'name': const NeatFieldState<String>(value: 'Johnny', initialValue: 'John'),
      };
      expect(dirtyMap.isDirty, isTrue);
    });
  });

  group('NeatFormState', () {
    test('instantiates with defaults and supports queries', () {
      const state = NeatFormState<String>(
        fields: {
          'email': NeatFieldState<String>(value: 'test@mail.com'),
          'age': NeatFieldState<int>(value: 25),
        },
      );

      expect(state.status, NeatSubmissionStatus.idle);
      expect(state.isSubmitting, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.isFailure, isFalse);
      expect(state.isValid, isTrue);
      expect(state.isCleanAndValid, isTrue);
      expect(state.isDirty, isFalse);
      expect(state.isValidating, isFalse);
      expect(state.valueOf<String>('email'), 'test@mail.com');
      expect(state.valueOf<int>('age'), 25);
      expect(state.getField<String>('email').value, 'test@mail.com');
      expect(state.errorOf('email'), isNull);
      expect(state.values, {'email': 'test@mail.com', 'age': 25});
      expect(state.toString(), contains('NeatFormState'));
    });

    test('instantiates with fromValues and supports field and operator []', () {
      final state = NeatFormState<String>.fromValues(
        {
          'email': 'test@mail.com',
          'age': 25,
        },
        optionalKeys: {'age': true},
      );

      expect(state.status, NeatSubmissionStatus.idle);
      expect(state.field<String>('email').value, 'test@mail.com');
      expect(state['email'].value, 'test@mail.com');
      expect(state.field<int>('age').isOptional, isTrue);
    });

    test('errorMessage returns message when isErrorVisible is true', () {
      const fieldValid = NeatFieldState<String>(value: 'ok');
      expect(fieldValid.errorMessage, isNull);

      const fieldErrorHidden = NeatFieldState<String>(
        value: '',
        error: NeatValidationError('required', message: 'Required field'),
        showError: false,
      );
      expect(fieldErrorHidden.errorMessage, isNull);

      const fieldErrorVisible = NeatFieldState<String>(
        value: '',
        error: NeatValidationError('required', message: 'Required field'),
        showError: true,
      );
      expect(fieldErrorVisible.errorMessage, 'Required field');
    });

    test('equality and copyWith work as expected', () {
      const state1 = NeatFormState<String>(
        fields: {'name': NeatFieldState<String>(value: 'Alice')},
        status: NeatSubmissionStatus.idle,
      );
      const state2 = NeatFormState<String>(
        fields: {'name': NeatFieldState<String>(value: 'Alice')},
        status: NeatSubmissionStatus.idle,
      );
      const stateDiffField = NeatFormState<String>(
        fields: {'name': NeatFieldState<String>(value: 'Bob')},
        status: NeatSubmissionStatus.idle,
      );
      const stateDiffLength = NeatFormState<String>(
        fields: {
          'name': NeatFieldState<String>(value: 'Alice'),
          'age': NeatFieldState<int>(value: 20),
        },
        status: NeatSubmissionStatus.idle,
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
      expect(state1 == stateDiffField, isFalse);
      expect(state1 == stateDiffLength, isFalse);
      expect(state1 == Object(), isFalse);

      final submittingState = state1.copyWith(status: NeatSubmissionStatus.submitting);
      expect(submittingState.isSubmitting, isTrue);

      final successState = state1.copyWith(status: NeatSubmissionStatus.success);
      expect(successState.isSuccess, isTrue);

      final failureState = state1.copyWith(status: NeatSubmissionStatus.failure);
      expect(failureState.isFailure, isTrue);
    });
  });
}
