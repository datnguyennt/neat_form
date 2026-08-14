import 'package:flutter_test/flutter_test.dart';
import 'package:neat_form/neat_form.dart';

void main() {
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
        error: const NeatValidationError.code('test_error'),
      );

      expect(updated.value, 'world');
      expect(updated.showError, isTrue);
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
      ); // optional & empty is valid
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
  });
}
