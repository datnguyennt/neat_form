import 'package:flutter_test/flutter_test.dart';
import 'package:neat_form/neat_form.dart';

enum TestFormKey { email, password }

// ==========================================
// 1. MOCK RIVERPOD NOTIFIER (STANDALONE FORM)
// ==========================================

class MockRiverpodNotifier with NeatFormNotifierMixin<TestFormKey> {
  MockRiverpodNotifier()
      : _state = NeatFormState.fromValues({
          TestFormKey.email: '',
          TestFormKey.password: '',
        });

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
  MockNestedRiverpodNotifier()
      : _state = MockScreenState(
          form: NeatFormState.fromValues({
            TestFormKey.email: '',
            TestFormKey.password: '',
          }),
        );

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
        TestFormKey.password: NeatValidators.combine([
          NeatValidators.required(message: 'Password required'),
          NeatValidators.minLength(6),
        ]),
      };
}

// ==========================================
// 3. MOCK CUBIT (STANDALONE FORM)
// ==========================================

class MockCubit with NeatFormCubitMixin<TestFormKey> {
  MockCubit()
      : _state = NeatFormState.fromValues({
          TestFormKey.email: '',
          TestFormKey.password: '',
        });

  NeatFormState<TestFormKey> _state;

  @override
  NeatFormState<TestFormKey> get state => _state;

  @override
  void emit(NeatFormState<TestFormKey> state) {
    _state = state;
  }

  @override
  Map<TestFormKey, NeatValidator<Object?>> get validators => {
        TestFormKey.email: NeatValidators.required(message: 'Email required'),
        TestFormKey.password: NeatValidators.required(),
      };
}

// ==========================================
// 4. MOCK CUBIT (NESTED / FREEZED SCREEN STATE)
// ==========================================

class MockNestedCubit
    with NeatNestedFormCubitMixin<MockScreenState, TestFormKey> {
  MockNestedCubit()
      : _state = MockScreenState(
          form: NeatFormState.fromValues({
            TestFormKey.email: '',
            TestFormKey.password: '',
          }),
        );

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
        TestFormKey.password: NeatValidators.combine([
          NeatValidators.required(),
          NeatValidators.minLength(8),
        ]),
      };
}

void main() {
  group('NeatFormNotifierMixin (Single Riverpod Notifier)', () {
    test('setField and validation lifecycle work correctly', () async {
      final notifier = MockRiverpodNotifier();

      expect(notifier.fields[TestFormKey.email]?.value, '');
      expect(notifier.submissionStatus, NeatSubmissionStatus.idle);

      // Set valid email
      notifier.setField(TestFormKey.email, 'test@example.com');
      expect(notifier.fields[TestFormKey.email]?.value, 'test@example.com');
      expect(notifier.fields.isDirty, isTrue);

      // Submit invalid (password empty)
      var submitCallbackCalled = false;
      var errorCallbackCalled = false;
      final success = await notifier.submitForm(
        onSubmit: (_) async => submitCallbackCalled = true,
        onError: (errors) {
          errorCallbackCalled = true;
          expect(errors.containsKey(TestFormKey.password), isTrue);
        },
      );

      expect(success, isFalse);
      expect(submitCallbackCalled, isFalse);
      expect(errorCallbackCalled, isTrue);
      expect(notifier.submissionStatus, NeatSubmissionStatus.failure);
      expect(notifier.getField<String>(TestFormKey.password).errorMessage,
          'Password required');

      // Fill password and submit successfully
      notifier.setField(TestFormKey.password, 'password123');
      final validSubmit = await notifier.submitForm(
        onSubmit: (values) async {
          expect(values[TestFormKey.email], 'test@example.com');
          expect(values[TestFormKey.password], 'password123');
          submitCallbackCalled = true;
        },
      );

      expect(validSubmit, isTrue);
      expect(submitCallbackCalled, isTrue);
      expect(notifier.submissionStatus, NeatSubmissionStatus.success);

      // Reset
      notifier.resetForm();
      expect(notifier.fields[TestFormKey.email]?.value, '');
      expect(notifier.submissionStatus, NeatSubmissionStatus.idle);
    });

    test('async validation with race condition token works in Notifier',
        () async {
      final notifier = MockRiverpodNotifier();

      final future1 = notifier.validateFieldAsync<String>(
        TestFormKey.email,
        (val) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return const NeatValidationError('old_token');
        },
      );

      // User continues typing immediately
      notifier.setField(TestFormKey.email, 'new@example.com');
      final future2 = notifier.validateFieldAsync<String>(
        TestFormKey.email,
        (val) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return null; // Valid!
        },
      );

      await Future.wait([future1, future2]);

      expect(notifier.getField<String>(TestFormKey.email).isValid, isTrue);
      expect(
          notifier.getField<String>(TestFormKey.email).isValidating, isFalse);
    });
  });

  group('NeatNestedFormNotifierMixin (Riverpod Freezed / Nested State)', () {
    test('updates nested form inside parent state without losing extra data',
        () async {
      final notifier = MockNestedRiverpodNotifier();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.fields[TestFormKey.email]?.value, '');

      // Set value in nested form
      notifier.setField(TestFormKey.email, 'nested@test.com');
      expect(notifier.state.form.valueOf<String>(TestFormKey.email),
          'nested@test.com');
      expect(notifier.state.isLoading, isFalse);

      // Validate nested form
      final isValid = notifier.validateForm();
      expect(isValid, isFalse); // password is empty (<6)

      expect(
        notifier.getField<String>(TestFormKey.password).isErrorVisible,
        isTrue,
      );

      // Submit nested form
      notifier.setField(TestFormKey.password, 'secret123');
      final submitSuccess = await notifier.submitForm(
        onSubmit: (values) async {
          expect(values[TestFormKey.email], 'nested@test.com');
        },
      );

      expect(submitSuccess, isTrue);
      expect(notifier.submissionStatus, NeatSubmissionStatus.success);
      expect(notifier.state.form.status, NeatSubmissionStatus.success);
    });
  });

  group('NeatFormCubitMixin (Standalone Cubit)', () {
    test('updates state via emit seamlessly', () async {
      final cubit = MockCubit();

      expect(cubit.state.fields[TestFormKey.email]?.value, '');

      cubit.setField(TestFormKey.email, 'cubit@flutter.dev');
      expect(cubit.state.valueOf<String>(TestFormKey.email),
          'cubit@flutter.dev');

      cubit.setField(TestFormKey.password, 'secret');
      final success = await cubit.submitForm(
        onSubmit: (values) async {
          expect(values[TestFormKey.email], 'cubit@flutter.dev');
        },
      );

      expect(success, isTrue);
      expect(cubit.submissionStatus, NeatSubmissionStatus.success);
      expect(cubit.state.status, NeatSubmissionStatus.success);
    });
  });

  group('NeatNestedFormCubitMixin (Cubit Freezed / Nested State)', () {
    test('updates nested form in Cubit state via emit', () async {
      final cubit = MockNestedCubit();

      expect(cubit.state.form.fields[TestFormKey.email]?.value, '');

      cubit.setField(TestFormKey.email, 'nested_cubit@flutter.dev');
      expect(cubit.state.form.valueOf<String>(TestFormKey.email),
          'nested_cubit@flutter.dev');

      cubit.setField(TestFormKey.password, 'password123');
      final success = await cubit.submitForm(
        onSubmit: (values) async {
          expect(values[TestFormKey.email], 'nested_cubit@flutter.dev');
        },
      );

      expect(success, isTrue);
      expect(cubit.submissionStatus, NeatSubmissionStatus.success);
      expect(cubit.state.form.status, NeatSubmissionStatus.success);
    });
  });
}
