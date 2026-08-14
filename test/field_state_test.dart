import 'package:neat_form/neat_form.dart';
import 'package:test/test.dart';

void main() {
  group('NeatFieldState', () {
    test('lifecycle flags and status calculation', () {
      const state = NeatFieldState<String>(
        value: '',
        initialValue: '',
      );

      expect(state.isValid, isTrue);
      expect(state.isInvalid, isFalse);
      expect(state.isEmpty, isTrue);
      expect(state.isNotEmpty, isFalse);
      expect(state.isDirty, isFalse);
      expect(state.isShowError, isFalse);
    });

    test('isDirty calculation when value changes', () {
      const state = NeatFieldState<String>(
        value: 'new_value',
        initialValue: 'old_value',
      );

      expect(state.isDirty, isTrue);
    });

    test('showError is true only when showError flag is true AND field is invalid', () {
      const validWithErrorHidden = NeatFieldState<String>(
        value: 'abc',
        error: NeatValidationError.code('error'),
      );
      expect(validWithErrorHidden.isShowError, isFalse);

      const invalidWithErrorShown = NeatFieldState<String>(
        value: 'abc',
        error: NeatValidationError.code('error'),
        showError: true,
      );
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

    test('copyWith updates state correctly', () {
      const initial = NeatFieldState<String>(value: 'hello');
      final updated = initial.copyWith(
        value: 'world',
        showError: true,
        error: () => const NeatValidationError.code('test_error'),
      );

      expect(updated.value, 'world');
      expect(updated.showError, isTrue);
      expect(updated.error?.code, 'test_error');
    });
  });

  group('NeatFormFieldMapExtension', () {
    test('isFilledAndValid and isAllFieldsValid evaluate correctly', () {
      final map = <String, NeatFieldState<dynamic>>{
        'email': const NeatFieldState<String>(value: 'test@example.com'),
        'password': const NeatFieldState<String>(value: '12345678'),
        'nickname': const NeatFieldState<String>(value: '', isOptional: true),
      };

      expect(map.isFilledAndValid('email'), isTrue);
      expect(map.isFilledAndValid('password'), isTrue);
      expect(map.isFilledAndValid('nickname'), isTrue); // optional & empty is valid
      expect(map.isAllFieldsValid, isTrue);
    });

    test('isAllFieldsValid returns false if a required field is empty', () {
      final map = <String, NeatFieldState<dynamic>>{
        'email': const NeatFieldState<String>(value: ''),
        'password': const NeatFieldState<String>(value: '12345678'),
      };

      expect(map.isFilledAndValid('email'), isFalse);
      expect(map.isAllFieldsValid, isFalse);
    });

    test('toValuesMap extracts raw values', () {
      final map = <String, NeatFieldState<dynamic>>{
        'email': const NeatFieldState<String>(value: 'a@b.com'),
        'age': const NeatFieldState<int>(value: 25),
      };

      final values = map.toValuesMap();
      expect(values, {'email': 'a@b.com', 'age': 25});
    });
  });
}
