import 'package:flutter_test/flutter_test.dart';
import 'package:neat_form/neat_form.dart';

enum TestFormKey { email, password }

// ==========================================
// 1. MOCK RIVERPOD NOTIFIER (STANDALONE FORM)
// ==========================================

class TestObserver extends NeatFormObserver<TestFormKey> {
  int fieldChangedCount = 0;
  int validationErrorCount = 0;
  int formSubmittedCount = 0;
  int formResetCount = 0;
  final List<NeatSubmissionStatus> statusHistory = [];

  @override
  void onFieldChanged(TestFormKey key, Object? value) => fieldChangedCount++;

  @override
  void onValidationError(TestFormKey key, NeatValidationError error) =>
      validationErrorCount++;

  @override
  void onFormSubmitted(Map<TestFormKey, Object?> values, {required bool isValid}) =>
      formSubmittedCount++;

  @override
  void onSubmissionStatusChanged(NeatSubmissionStatus status) =>
      statusHistory.add(status);

  @override
  void onFormReset() => formResetCount++;
}

class MockRiverpodNotifier with NeatFormNotifierMixin<TestFormKey> {
  MockRiverpodNotifier({this.testObserver})
      : _state = NeatFormState.fromValues({
          TestFormKey.email: '',
          TestFormKey.password: '',
        });

  final TestObserver? testObserver;

  @override
  NeatFormObserver<TestFormKey>? get observer => testObserver;

  NeatFormState<TestFormKey> _state;

  @override
  NeatFormState<TestFormKey> get state => _state;

  @override
  set state(NeatFormState<TestFormKey> value) {
    _state = value;
  }

  @override
  Map<TestFormKey, NeatValidator<Object?>> get validators => {
        TestFormKey.email: NeatValidators.combine([
          NeatValidators.required(message: 'Email required'),
          NeatValidators.email(message: 'Email invalid'),
        ]),
        TestFormKey.password: NeatValidators.combine([
          NeatValidators.required(message: 'Password required'),
          NeatValidators.minLength(6, message: 'Password min 6 chars'),
        ]),
      };
}

// ==========================================
// 2. MOCK RIVERPOD NOTIFIER (NESTED / FREEZED SCREEN STATE)
// ==========================================

class MockScreenState {
  const MockScreenState({
    required this.form,
    this.isLoading = false,
    this.extraData = '',
  });

  final NeatFormState<TestFormKey> form;
  final bool isLoading;
  final String extraData;

  MockScreenState copyWith({
    NeatFormState<TestFormKey>? form,
    bool? isLoading,
    String? extraData,
  }) {
    return MockScreenState(
      form: form ?? this.form,
      isLoading: isLoading ?? this.isLoading,
      extraData: extraData ?? this.extraData,
    );
  }
}

class MockNestedRiverpodNotifier
    with NeatNestedFormNotifierMixin<MockScreenState, TestFormKey> {
  MockNestedRiverpodNotifier({this.testObserver})
      : _state = MockScreenState(
          form: NeatFormState.fromValues({
            TestFormKey.email: '',
            TestFormKey.password: '',
          }),
        );

  final TestObserver? testObserver;

  @override
  NeatFormObserver<TestFormKey>? get observer => testObserver;

  MockScreenState _state;

  @override
  MockScreenState get state => _state;

  @override
  set state(MockScreenState value) {
    _state = value;
  }

  @override
  NeatFormState<TestFormKey> getForm(MockScreenState state) => state.form;

  @override
  MockScreenState updateForm(
    MockScreenState state,
    NeatFormState<TestFormKey> form,
  ) =>
      state.copyWith(form: form);

  @override
  Map<TestFormKey, NeatValidator<Object?>> get validators => {
        TestFormKey.email: NeatValidators.required(message: 'Email required'),
        TestFormKey.password: NeatValidators.required(message: 'Password required'),
      };
}

// ==========================================
// 3. MOCK BLOC / CUBIT (STANDALONE FORM)
// ==========================================

class MockCubit with NeatFormCubitMixin<TestFormKey> {
  MockCubit({this.testObserver})
      : _state = NeatFormState.fromValues({
          TestFormKey.email: '',
          TestFormKey.password: '',
        });

  final TestObserver? testObserver;

  @override
  NeatFormObserver<TestFormKey>? get observer => testObserver;

  NeatFormState<TestFormKey> _state;

  @override
  NeatFormState<TestFormKey> get state => _state;

  @override
  void emit(NeatFormState<TestFormKey> state) {
    _state = state;
  }

  @override
  Map<TestFormKey, NeatValidator<Object?>> get validators => {
        TestFormKey.email: NeatValidators.required(),
        TestFormKey.password: NeatValidators.minLength(6),
      };
}

// ==========================================
// 4. MOCK BLOC / CUBIT (NESTED SCREEN STATE)
// ==========================================

class MockNestedCubit with NeatNestedFormCubitMixin<MockScreenState, TestFormKey> {
  MockNestedCubit({this.testObserver})
      : _state = MockScreenState(
          form: NeatFormState.fromValues({
            TestFormKey.email: '',
            TestFormKey.password: '',
          }),
        );

  final TestObserver? testObserver;

  @override
  NeatFormObserver<TestFormKey>? get observer => testObserver;

  MockScreenState _state;

  @override
  MockScreenState get state => _state;

  @override
  void emit(MockScreenState state) {
    _state = state;
  }

  @override
  NeatFormState<TestFormKey> getForm(MockScreenState state) => state.form;

  @override
  MockScreenState updateForm(
    MockScreenState state,
    NeatFormState<TestFormKey> form,
  ) =>
      state.copyWith(form: form);

  @override
  Map<TestFormKey, NeatValidator<Object?>> get validators => {
        TestFormKey.email: NeatValidators.required(),
        TestFormKey.password: NeatValidators.required(),
      };
}

class DefaultObserver extends NeatFormObserver<TestFormKey> {
  const DefaultObserver();
}

void main() {
  group('Default NeatFormObserver callbacks', () {
    test('default empty callback implementations execute without error', () {
      const obs = DefaultObserver();
      obs.onFieldChanged(TestFormKey.email, 'test');
      obs.onValidationError(
        TestFormKey.email,
        const NeatValidationError.code('error'),
      );
      obs.onFormSubmitted({TestFormKey.email: 'test'}, isValid: true);
      obs.onSubmissionStatusChanged(NeatSubmissionStatus.submitting);
      obs.onFormReset();
    });
  });

  group('NeatFormNotifierMixin (Single Riverpod Notifier)', () {
    late MockRiverpodNotifier notifier;
    late TestObserver observer;

    setUp(() {
      observer = TestObserver();
      notifier = MockRiverpodNotifier(testObserver: observer);
    });

    test('initial state is cleanly initialized with idle status', () {
      expect(notifier.fields.length, 2);
      expect(notifier.submissionStatus, NeatSubmissionStatus.idle);
      expect(notifier.getField<String>(TestFormKey.email).value, '');
      expect(notifier.getField<String>(TestFormKey.password).value, '');
      expect(notifier.state.isDirty, isFalse);
    });

    test('setField updates state surgically and notifies observer', () {
      notifier.setField(TestFormKey.email, 'john@example.com');
      expect(
        notifier.getField<String>(TestFormKey.email).value,
        'john@example.com',
      );
      expect(notifier.state.isDirty, isTrue);
      expect(observer.fieldChangedCount, 1);
    });

    test('setAndValidateField updates and validates field immediately', () {
      final error = notifier.setAndValidateField(TestFormKey.email, 'invalid_email');
      expect(error, isNotNull);
      expect(error?.code, NeatValidators.codeEmail);
      expect(notifier.getField<String>(TestFormKey.email).isErrorVisible, isTrue);
      expect(observer.validationErrorCount, 1);
    });

    test('validateField runs single field validator and updates state', () {
      final error = notifier.validateField<String>(TestFormKey.email);
      expect(error, isNotNull);
      expect(error?.code, NeatValidators.codeRequired);
      expect(notifier.getField<String>(TestFormKey.email).showError, isTrue);
    });

    test('validateForm validates all fields and updates form state', () {
      final isValidInitial = notifier.validateForm();
      expect(isValidInitial, isFalse);
      expect(notifier.getField<String>(TestFormKey.email).showError, isTrue);
      expect(notifier.getField<String>(TestFormKey.password).showError, isTrue);

      notifier.setField(TestFormKey.email, 'user@test.com');
      notifier.setField(TestFormKey.password, '123456');

      final isValidFilled = notifier.validateForm();
      expect(isValidFilled, isTrue);
    });

    test('updateField and clearErrors work correctly', () {
      notifier.setAndValidateField(TestFormKey.email, 'invalid');
      expect(notifier.getField<String>(TestFormKey.email).error, isNotNull);

      notifier.clearErrors();
      expect(notifier.getField<String>(TestFormKey.email).error, isNull);

      notifier.updateField<String>(
        TestFormKey.email,
        (current) => current.copyWith(value: 'updated_via_updater'),
      );
      expect(notifier.getField<String>(TestFormKey.email).value, 'updated_via_updater');
    });

    test('submitForm handles valid and invalid flow and exceptions', () async {
      // 1. Invalid submit
      final invalidResult = await notifier.submitForm(onSubmit: (v) async {});
      expect(invalidResult, isFalse);
      expect(notifier.submissionStatus, NeatSubmissionStatus.failure);

      // 2. Valid submit
      notifier.setField(TestFormKey.email, 'valid@email.com');
      notifier.setField(TestFormKey.password, 'password123');

      final validResult = await notifier.submitForm(onSubmit: (v) async {});
      expect(validResult, isTrue);
      expect(notifier.submissionStatus, NeatSubmissionStatus.success);

      // 3. Exception in onSubmit
      await expectLater(
        () => notifier.submitForm(onSubmit: (v) async {
          throw Exception('Server 500 error');
        }),
        throwsA(isA<Exception>()),
      );
      expect(notifier.submissionStatus, NeatSubmissionStatus.failure);

      // 4. Reset restores idle
      notifier.resetForm();
      expect(notifier.submissionStatus, NeatSubmissionStatus.idle);
      expect(notifier.getField<String>(TestFormKey.email).value, '');
      expect(observer.formResetCount, 1);
    });

    test('resetField resets single field', () {
      notifier.setField(TestFormKey.email, 'test@abc.com');
      expect(notifier.getField<String>(TestFormKey.email).value, 'test@abc.com');

      notifier.resetField<String>(TestFormKey.email);
      expect(notifier.getField<String>(TestFormKey.email).value, '');
    });

    test('async validation with race condition token works in Notifier', () async {
      Future<NeatValidationError?> checkEmail(String? email) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (email == 'taken@test.com') {
          return const NeatValidationError.code('email_taken');
        }
        return null;
      }

      notifier.setField(TestFormKey.email, 'taken@test.com');
      final error = await notifier.validateFieldAsync(
        TestFormKey.email,
        checkEmail,
      );

      expect(error?.code, 'email_taken');
      expect(notifier.getField<String>(TestFormKey.email).error?.code, 'email_taken');
      expect(notifier.getField<String>(TestFormKey.email).isValidating, isFalse);
    });
  });

  group('NeatNestedFormNotifierMixin (Nested Freezed Screen State)', () {
    late MockNestedRiverpodNotifier notifier;
    late TestObserver observer;

    setUp(() {
      observer = TestObserver();
      notifier = MockNestedRiverpodNotifier(testObserver: observer);
    });

    test('accesses and updates nested form state properly', () {
      expect(notifier.fields.length, 2);
      expect(notifier.submissionStatus, NeatSubmissionStatus.idle);

      notifier.setField(TestFormKey.email, 'nested@test.com');
      expect(notifier.getField<String>(TestFormKey.email).value, 'nested@test.com');
      expect(notifier.fields.isDirty, isTrue);

      notifier.clearErrors();
      expect(notifier.getField<String>(TestFormKey.email).error, isNull);

      notifier.updateField<String>(
        TestFormKey.email,
        (current) => current.copyWith(value: 'nested_updater'),
      );
      expect(notifier.getField<String>(TestFormKey.email).value, 'nested_updater');

      final error = notifier.setAndValidateField(TestFormKey.email, '');
      expect(error?.code, NeatValidators.codeRequired);

      final valErr = notifier.validateField<String>(TestFormKey.password);
      expect(valErr?.code, NeatValidators.codeRequired);
    });

    test('submitForm in nested notifier handles lifecycle and exceptions', () async {
      final invalidRes = await notifier.submitForm(onSubmit: (v) async {});
      expect(invalidRes, isFalse);
      expect(notifier.submissionStatus, NeatSubmissionStatus.failure);

      notifier.setField(TestFormKey.email, 'ok@test.com');
      notifier.setField(TestFormKey.password, 'secret');

      final validRes = await notifier.submitForm(onSubmit: (v) async {});
      expect(validRes, isTrue);
      expect(notifier.submissionStatus, NeatSubmissionStatus.success);

      await expectLater(
        () => notifier.submitForm(onSubmit: (v) async {
          throw StateError('Failed submission');
        }),
        throwsA(isA<StateError>()),
      );
      expect(notifier.submissionStatus, NeatSubmissionStatus.failure);

      notifier.resetField<String>(TestFormKey.email);
      notifier.resetForm();
      expect(notifier.submissionStatus, NeatSubmissionStatus.idle);
    });

    test('async validation in nested notifier', () async {
      notifier.setField(TestFormKey.email, 'check@mail.com');
      final err = await notifier.validateFieldAsync<String>(
        TestFormKey.email,
        (val) async => const NeatValidationError.code('custom_async'),
      );
      expect(err?.code, 'custom_async');
    });
  });

  group('NeatFormCubitMixin (BLoC / Cubit Standalone)', () {
    late MockCubit cubit;
    late TestObserver observer;

    setUp(() {
      observer = TestObserver();
      cubit = MockCubit(testObserver: observer);
    });

    test('operates all cubit methods correctly', () async {
      expect(cubit.fields.length, 2);
      expect(cubit.submissionStatus, NeatSubmissionStatus.idle);

      cubit.setField(TestFormKey.email, 'cubit@test.com');
      expect(cubit.getField<String>(TestFormKey.email).value, 'cubit@test.com');
      expect(cubit.state.isDirty, isTrue);

      final err = cubit.setAndValidateField(TestFormKey.password, '123');
      expect(err?.code, NeatValidators.codeMinLength);

      final valErr = cubit.validateField<String>(TestFormKey.email);
      expect(valErr, isNull);

      cubit.clearErrors();
      expect(cubit.getField<String>(TestFormKey.email).error, isNull);

      cubit.updateField<String>(
        TestFormKey.email,
        (current) => current.copyWith(value: 'cubit_updated'),
      );
      expect(cubit.getField<String>(TestFormKey.email).value, 'cubit_updated');

      final asyncErr = await cubit.validateFieldAsync<String>(
        TestFormKey.email,
        (v) async => const NeatValidationError.code('cubit_async'),
      );
      expect(asyncErr?.code, 'cubit_async');

      final submitFail = await cubit.submitForm(onSubmit: (v) async {});
      expect(submitFail, isFalse);

      cubit.setField(TestFormKey.email, 'cubit@ok.com');
      cubit.setField(TestFormKey.password, '123456');
      final submitOk = await cubit.submitForm(onSubmit: (v) async {});
      expect(submitOk, isTrue);
      expect(cubit.submissionStatus, NeatSubmissionStatus.success);

      await expectLater(
        () => cubit.submitForm(onSubmit: (v) async {
          throw Exception('network failure');
        }),
        throwsA(isA<Exception>()),
      );
      expect(cubit.submissionStatus, NeatSubmissionStatus.failure);

      cubit.resetField<String>(TestFormKey.email);
      cubit.resetForm();
      expect(cubit.submissionStatus, NeatSubmissionStatus.idle);
    });
  });

  group('NeatNestedFormCubitMixin (BLoC / Cubit Nested State)', () {
    late MockNestedCubit cubit;
    late TestObserver observer;

    setUp(() {
      observer = TestObserver();
      cubit = MockNestedCubit(testObserver: observer);
    });

    test('operates all nested cubit methods correctly', () async {
      expect(cubit.fields.length, 2);
      expect(cubit.submissionStatus, NeatSubmissionStatus.idle);

      cubit.setField(TestFormKey.email, 'nested_cubit@test.com');
      expect(cubit.getField<String>(TestFormKey.email).value, 'nested_cubit@test.com');
      expect(cubit.fields.isDirty, isTrue);

      final err = cubit.setAndValidateField(TestFormKey.email, '');
      expect(err?.code, NeatValidators.codeRequired);

      final valErr = cubit.validateField<String>(TestFormKey.password);
      expect(valErr?.code, NeatValidators.codeRequired);

      cubit.clearErrors();
      expect(cubit.getField<String>(TestFormKey.email).error, isNull);

      cubit.updateField<String>(
        TestFormKey.email,
        (current) => current.copyWith(value: 'cubit_nest_updated'),
      );
      expect(cubit.getField<String>(TestFormKey.email).value, 'cubit_nest_updated');

      final asyncErr = await cubit.validateFieldAsync<String>(
        TestFormKey.email,
        (v) async => const NeatValidationError.code('async_nest_err'),
      );
      expect(asyncErr?.code, 'async_nest_err');

      final submitFail = await cubit.submitForm(onSubmit: (v) async {});
      expect(submitFail, isFalse);

      cubit.setField(TestFormKey.email, 'nest@ok.com');
      cubit.setField(TestFormKey.password, 'secret');
      final submitOk = await cubit.submitForm(onSubmit: (v) async {});
      expect(submitOk, isTrue);
      expect(cubit.submissionStatus, NeatSubmissionStatus.success);

      await expectLater(
        () => cubit.submitForm(onSubmit: (v) async {
          throw Exception('network failure');
        }),
        throwsA(isA<Exception>()),
      );
      expect(cubit.submissionStatus, NeatSubmissionStatus.failure);

      cubit.resetField<String>(TestFormKey.email);
      cubit.resetForm();
      expect(cubit.submissionStatus, NeatSubmissionStatus.idle);
    });
  });
}
