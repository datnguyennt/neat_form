import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neat_form/neat_form.dart';

enum TestKey { username, age }

class TestObserver extends NeatFormObserver<TestKey> {
  int fieldChangedCount = 0;
  int validationErrorCount = 0;
  int formSubmittedCount = 0;
  int formResetCount = 0;
  final List<NeatSubmissionStatus> statusHistory = [];

  @override
  void onFieldChanged(TestKey key, Object? value) => fieldChangedCount++;

  @override
  void onValidationError(TestKey key, NeatValidationError error) =>
      validationErrorCount++;

  @override
  void onFormSubmitted(Map<TestKey, Object?> values, {required bool isValid}) =>
      formSubmittedCount++;

  @override
  void onSubmissionStatusChanged(NeatSubmissionStatus status) =>
      statusHistory.add(status);

  @override
  void onFormReset() => formResetCount++;
}

class TestFormController with NeatFormMixin<TestKey> {
  TestFormController({this.testObserver});

  final TestObserver? testObserver;

  @override
  NeatFormObserver<TestKey>? get observer => testObserver;

  Map<TestKey, NeatFieldState<Object?>> _fields = {
    TestKey.username: const NeatFieldState<String>(value: ''),
    TestKey.age: const NeatFieldState<int?>(value: null),
  };

  @override
  Map<TestKey, NeatFieldState<Object?>> get fields => _fields;

  @override
  Map<TestKey, NeatValidator<Object?>> get validators => {
        TestKey.username: NeatValidators.combine([
          NeatValidators.required(),
          NeatValidators.minLength(3),
        ]),
        TestKey.age: NeatValidators.combine([
          NeatValidators.required(),
          (val) => val is int && val >= 18
              ? null
              : const NeatValidationError.code('underage'),
        ]),
      };

  @override
  void updateStateWithFields(Map<TestKey, NeatFieldState<Object?>> newFields) {
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
      expect(
        controller.getField<String>(TestKey.username).isErrorVisible,
        isTrue,
      );

      final validError =
          controller.setAndValidateField(TestKey.username, 'abc');
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
      expect(
        controller.getField<String>(TestKey.username).error?.code,
        'username_taken',
      );
      expect(
        controller.getField<String>(TestKey.username).isValidating,
        isFalse,
      );
    });

    test(
        'validateFieldAsync prevents race conditions when new async validation starts for same value sequence',
        () async {
      var callCount = 0;
      Future<NeatValidationError?> slowCheck(String? val) async {
        callCount++;
        final myCall = callCount;
        if (myCall == 1) {
          await Future<void>.delayed(const Duration(milliseconds: 40));
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        return const NeatValidationError.code('async_error');
      }

      controller.setField(TestKey.username, 'abc');

      final future1 = controller.validateFieldAsync(
        TestKey.username,
        slowCheck,
      );

      final future2 = controller.validateFieldAsync(
        TestKey.username,
        slowCheck,
      );

      await future2;
      expect(
        controller.getField<String>(TestKey.username).isValidating,
        isFalse,
      );

      await future1;
      expect(
        controller.getField<String>(TestKey.username).isValidating,
        isFalse,
      );
    });

    test('resetForm invalidates pending async validations', () async {
      Future<NeatValidationError?> slowCheck(String? val) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return const NeatValidationError.code('async_error');
      }

      controller.setField(TestKey.username, 'abc');
      final asyncFuture = controller.validateFieldAsync(
        TestKey.username,
        slowCheck,
      );

      // Reset form while validation is still in progress
      controller.resetForm();
      expect(controller.getField<String>(TestKey.username).value, '');
      expect(controller.getField<String>(TestKey.username).error, isNull);

      await asyncFuture;

      // Ensure error was not committed after reset
      expect(controller.getField<String>(TestKey.username).error, isNull);
      expect(controller.getField<String>(TestKey.username).value, '');
    });

    test('submitForm manages submissionStatus and observer lifecycle',
        () async {
      final observer = TestObserver();
      final obsController = TestFormController(testObserver: observer);

      expect(obsController.submissionStatus, NeatSubmissionStatus.idle);

      // Invalid submit
      final failed = await obsController.submitForm(
        onSubmit: (values) async {},
      );
      expect(failed, isFalse);
      expect(obsController.submissionStatus, NeatSubmissionStatus.failure);
      expect(observer.statusHistory, [
        NeatSubmissionStatus.submitting,
        NeatSubmissionStatus.failure,
      ]);

      // Valid submit
      obsController.setField(TestKey.username, 'valid_user');
      obsController.setField(TestKey.age, 25);

      final success = await obsController.submitForm(
        onSubmit: (values) async {},
      );
      expect(success, isTrue);
      expect(obsController.submissionStatus, NeatSubmissionStatus.success);

      // Reset restores status to idle
      obsController.resetForm();
      expect(obsController.submissionStatus, NeatSubmissionStatus.idle);
    });

    test('resetField and resetForm restore initial values and clear errors',
        () {
      controller.setAndValidateField(TestKey.username, 'invalid');
      controller.setAndValidateField(TestKey.age, 12);

      expect(controller.getField<String>(TestKey.username).value, 'invalid');
      expect(controller.getField<int?>(TestKey.age).value, 12);
      expect(controller.getField<int?>(TestKey.age).isInvalid, isTrue);

      // Reset single field
      controller.resetField<String>(TestKey.username);
      expect(controller.getField<String>(TestKey.username).value, '');
      expect(controller.getField<String>(TestKey.username).error, isNull);
      expect(controller.getField<String>(TestKey.username).showError, isFalse);

      // Reset entire form
      controller.resetForm();
      expect(controller.getField<int?>(TestKey.age).value, isNull);
      expect(controller.getField<int?>(TestKey.age).error, isNull);
      expect(controller.getField<int?>(TestKey.age).showError, isFalse);
    });
  });

  group('NeatFormController with Flutter integration', () {
    test('notifies listeners when field state updates and status updates', () {
      final formCtrl = NeatFormController<TestKey>(
        initialFields: {
          TestKey.username: const NeatFieldState<String>(value: ''),
        },
        validators: {
          TestKey.username: NeatValidators.required(),
        },
      );

      var notifyCount = 0;
      formCtrl.addListener(() {
        notifyCount++;
      });

      formCtrl.setField(TestKey.username, 'hello');
      expect(notifyCount, 1);
      expect(formCtrl.getField<String>(TestKey.username).value, 'hello');

      formCtrl.dispose();
      expect(formCtrl.isDisposed, isTrue);

      formCtrl.setField(TestKey.username, 'after dispose');
      expect(notifyCount, 1);
    });

    testWidgets('works seamlessly with Flutter ListenableBuilder',
        (tester) async {
      final formCtrl = NeatFormController<TestKey>(
        initialFields: {
          TestKey.username: const NeatFieldState<String>(value: 'initial'),
        },
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ListenableBuilder(
            listenable: formCtrl,
            builder: (context, child) {
              return Text(
                formCtrl.getField<String>(TestKey.username).value,
              );
            },
          ),
        ),
      );

      expect(find.text('initial'), findsOneWidget);

      formCtrl.setField(TestKey.username, 'updated');
      await tester.pump();

      expect(find.text('updated'), findsOneWidget);

      formCtrl.dispose();
    });
  });

  group('NeatFormNotifierMixin', () {
    test('binds state automatically without manual overrides', () {
      final notifier = _SampleRiverpodNotifier();

      expect(notifier.fields.length, 2);
      expect(notifier.getField<String>(TestKey.username).value, 'john');
      expect(notifier.submissionStatus, NeatSubmissionStatus.idle);

      notifier.setField(TestKey.username, 'doe');
      expect(notifier.state.field<String>(TestKey.username).value, 'doe');

      final isValid = notifier.validateForm();
      expect(isValid, isTrue);
    });
  });
}

class _SampleRiverpodNotifier with NeatFormMixin<TestKey>, NeatFormNotifierMixin<TestKey> {
  NeatFormState<TestKey> _state = NeatFormState<TestKey>.fromValues({
    TestKey.username: 'john',
    TestKey.age: 30,
  });

  @override
  NeatFormState<TestKey> get state => _state;

  @override
  set state(NeatFormState<TestKey> value) => _state = value;

  @override
  Map<TestKey, NeatValidator<Object?>> get validators => {
        TestKey.username: NeatValidators.required(),
      };
}

