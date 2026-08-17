import 'package:flutter_test/flutter_test.dart';
import 'package:neat_form/neat_form.dart';

enum PassengerKey { fullName, passportNumber, seatType }

void main() {
  group('NeatFormArrayItem', () {
    test('instantiates with generated unique ID and explicit ID', () {
      final item1 = NeatFormArrayItem<PassengerKey>(
        form: NeatFormState<PassengerKey>.fromValues({
          PassengerKey.fullName: 'John Doe',
        }),
      );

      final item2 = NeatFormArrayItem<PassengerKey>(
        form: NeatFormState<PassengerKey>.fromValues({
          PassengerKey.fullName: 'Jane Doe',
        }),
      );

      expect(item1.id, isNotEmpty);
      expect(item2.id, isNotEmpty);
      expect(item1.id, isNot(equals(item2.id)));

      final explicitItem = NeatFormArrayItem<PassengerKey>(
        id: 'custom_id_123',
        form: NeatFormState<PassengerKey>.fromValues({
          PassengerKey.fullName: 'Alex',
        }),
      );
      expect(explicitItem.id, 'custom_id_123');
    });

    test('copyWith, equality, hashCode, toString', () {
      final item = NeatFormArrayItem<PassengerKey>(
        id: 'id_1',
        form: NeatFormState<PassengerKey>.fromValues({
          PassengerKey.fullName: 'John',
        }),
      );

      final clone = item.copyWith();
      expect(clone, equals(item));
      expect(clone.hashCode, equals(item.hashCode));
      expect(item == Object(), isFalse);

      final updatedId = item.copyWith(id: 'id_2');
      expect(updatedId.id, 'id_2');
      expect(updatedId == item, isFalse);

      final updatedForm = item.copyWith(
        form: NeatFormState<PassengerKey>.fromValues({
          PassengerKey.fullName: 'Johnny',
        }),
      );
      expect(updatedForm == item, isFalse);

      expect(item.toString(), contains('NeatFormArrayItem'));
      expect(item.toString(), contains('id_1'));
    });
  });

  group('NeatFormArrayState', () {
    test('initializes with fromValuesList and provides queries', () {
      final state = NeatFormArrayState<PassengerKey>.fromValuesList([
        {PassengerKey.fullName: 'Alice', PassengerKey.passportNumber: 'A123'},
        {PassengerKey.fullName: 'Bob', PassengerKey.passportNumber: 'B456'},
      ]);

      expect(state.length, 2);
      expect(state.isEmpty, isFalse);
      expect(state.isNotEmpty, isTrue);
      expect(state.isValid, isTrue);
      expect(state.isCleanAndValid, isTrue);
      expect(state.isDirty, isFalse);
      expect(state.isValidating, isFalse);
      expect(state.isSubmitting, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.isFailure, isFalse);
      expect(state.isErrorVisible, isFalse);
      expect(state.errorMessage, isNull);

      final values = state.values;
      expect(values.length, 2);
      expect(values[0][PassengerKey.fullName], 'Alice');
      expect(values[1][PassengerKey.fullName], 'Bob');

      expect(state[0].valueOf<String>(PassengerKey.fullName), 'Alice');
      expect(state[1].valueOf<String>(PassengerKey.fullName), 'Bob');
    });

    test('itemById and indexOfId find items correctly', () {
      final itemA = NeatFormArrayItem<PassengerKey>(
        id: 'id_a',
        form: NeatFormState<PassengerKey>.fromValues({
          PassengerKey.fullName: 'Alice',
        }),
      );
      final itemB = NeatFormArrayItem<PassengerKey>(
        id: 'id_b',
        form: NeatFormState<PassengerKey>.fromValues({
          PassengerKey.fullName: 'Bob',
        }),
      );

      final state = NeatFormArrayState<PassengerKey>(items: [itemA, itemB]);

      expect(state.itemById('id_a'), equals(itemA));
      expect(state.itemById('id_b'), equals(itemB));
      expect(state.itemById('non_existent'), isNull);

      expect(state.indexOfId('id_a'), 0);
      expect(state.indexOfId('id_b'), 1);
      expect(state.indexOfId('non_existent'), -1);
    });

    test('copyWith handles error nullability and flags correctly', () {
      const state = NeatFormArrayState<PassengerKey>();
      expect(state.error, isNull);

      final withErr = state.copyWith(
        error: const NeatValidationError('array_error', message: 'Err message'),
        showError: true,
        status: NeatSubmissionStatus.failure,
      );
      expect(withErr.error?.code, 'array_error');
      expect(withErr.isErrorVisible, isTrue);
      expect(withErr.errorMessage, 'Err message');
      expect(withErr.isFailure, isTrue);

      final clearedErr = withErr.copyWith(error: null);
      expect(clearedErr.error, isNull);
    });

    test('equality, hashCode, toString', () {
      final item = NeatFormArrayItem<PassengerKey>(
        id: 'id_1',
        form: NeatFormState<PassengerKey>.fromValues({
          PassengerKey.fullName: 'John',
        }),
      );

      final s1 = NeatFormArrayState<PassengerKey>(items: [item]);
      final s2 = NeatFormArrayState<PassengerKey>(items: [item]);
      final s3 = NeatFormArrayState<PassengerKey>(items: [
        item,
        NeatFormArrayItem<PassengerKey>(
          id: 'id_2',
          form: NeatFormState<PassengerKey>.fromValues({}),
        ),
      ]);

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1 == s3, isFalse);
      expect(s1 == Object(), isFalse);

      expect(s1.toString(), contains('NeatFormArrayState'));
    });
  });

  group('NeatArrayValidators', () {
    test('minItems & maxItems & lengthRange', () {
      final minV = NeatArrayValidators.minItems<PassengerKey>(2);
      final maxV = NeatArrayValidators.maxItems<PassengerKey>(3);
      final rangeV = NeatArrayValidators.lengthRange<PassengerKey>(2, 4);

      final state1 = NeatFormArrayState<PassengerKey>.fromValuesList([
        {PassengerKey.fullName: 'P1'},
      ]);
      final state2 = NeatFormArrayState<PassengerKey>.fromValuesList([
        {PassengerKey.fullName: 'P1'},
        {PassengerKey.fullName: 'P2'},
      ]);
      final state5 = NeatFormArrayState<PassengerKey>.fromValuesList([
        {PassengerKey.fullName: 'P1'},
        {PassengerKey.fullName: 'P2'},
        {PassengerKey.fullName: 'P3'},
        {PassengerKey.fullName: 'P4'},
        {PassengerKey.fullName: 'P5'},
      ]);

      expect(minV(state1), isNotNull);
      expect(minV(state2), isNull);

      expect(maxV(state2), isNull);
      expect(maxV(state5), isNotNull);

      expect(rangeV(state1), isNotNull);
      expect(rangeV(state2), isNull);
      expect(rangeV(state5), isNotNull);
    });

    test('uniqueBy validates distinct values across array items', () {
      final uniquePassport = NeatArrayValidators.uniqueBy<PassengerKey, String>(
        (form) => form.valueOf<String>(PassengerKey.passportNumber),
        code: 'duplicate_passport',
        message: 'Passport numbers must be unique',
      );

      final distinctState = NeatFormArrayState<PassengerKey>.fromValuesList([
        {PassengerKey.passportNumber: 'P100'},
        {PassengerKey.passportNumber: 'P200'},
        {PassengerKey.passportNumber: 'P300'},
      ]);
      expect(uniquePassport(distinctState), isNull);

      final duplicateState = NeatFormArrayState<PassengerKey>.fromValuesList([
        {PassengerKey.passportNumber: 'P100'},
        {PassengerKey.passportNumber: 'P200'},
        {PassengerKey.passportNumber: 'P100'},
      ]);
      final err = uniquePassport(duplicateState);
      expect(err, isNotNull);
      expect(err?.code, 'duplicate_passport');
      expect(err?.message, 'Passport numbers must be unique');

      // Empty string values ignored by default
      final emptyState = NeatFormArrayState<PassengerKey>.fromValuesList([
        {PassengerKey.passportNumber: ''},
        {PassengerKey.passportNumber: ''},
      ]);
      expect(uniquePassport(emptyState), isNull);
    });

    test('custom array validator evaluates predicate', () {
      final customV = NeatArrayValidators.custom<PassengerKey>(
        (state) => state.length.isEven,
        code: 'must_be_even_count',
      );

      final evenState = NeatFormArrayState<PassengerKey>.fromValuesList([
        {PassengerKey.fullName: 'A'},
        {PassengerKey.fullName: 'B'},
      ]);
      expect(customV(evenState), isNull);

      final oddState = NeatFormArrayState<PassengerKey>.fromValuesList([
        {PassengerKey.fullName: 'A'},
      ]);
      expect(customV(oddState)?.code, 'must_be_even_count');
    });
  });

  group('NeatFormArrayController', () {
    late NeatFormArrayController<PassengerKey> controller;

    setUp(() {
      controller = NeatFormArrayController<PassengerKey>(
        initialItems: [
          {
            PassengerKey.fullName: 'Passenger 1',
            PassengerKey.passportNumber: 'PASS1',
          },
        ],
        itemValidators: {
          PassengerKey.fullName: NeatValidators.required(),
          PassengerKey.passportNumber: NeatValidators.combine([
            NeatValidators.required(),
            NeatValidators.minLength(4),
          ]),
        },
        arrayValidators: [
          NeatArrayValidators.minItems(1),
          NeatArrayValidators.maxItems(3),
          NeatArrayValidators.uniqueBy(
            (f) => f.valueOf<String>(PassengerKey.passportNumber),
          ),
        ],
      );
    });

    test('addItem, insertItem, removeItemAt, removeItemById, moveItem', () {
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      // 1. Add item
      controller.addItem({
        PassengerKey.fullName: 'Passenger 2',
        PassengerKey.passportNumber: 'PASS2',
      });
      expect(controller.length, 2);
      expect(notifyCount, 1);
      expect(controller[1].valueOf<String>(PassengerKey.fullName), 'Passenger 2');

      // 2. Insert item at index 1
      controller.insertItem(1, {
        PassengerKey.fullName: 'Inserted Passenger',
        PassengerKey.passportNumber: 'PASS_MID',
      });
      expect(controller.length, 3);
      expect(controller[1].valueOf<String>(PassengerKey.fullName), 'Inserted Passenger');
      expect(controller[2].valueOf<String>(PassengerKey.fullName), 'Passenger 2');

      // Out of bounds insert
      expect(() => controller.insertItem(-1), throwsRangeError);
      expect(() => controller.insertItem(10), throwsRangeError);

      // 3. Move item from 0 to 2
      controller.moveItem(0, 2);
      expect(controller[0].valueOf<String>(PassengerKey.fullName), 'Inserted Passenger');
      expect(controller[1].valueOf<String>(PassengerKey.fullName), 'Passenger 1');
      expect(controller[2].valueOf<String>(PassengerKey.fullName), 'Passenger 2');

      // Move item upwards from 2 to 0
      controller.moveItem(2, 0);
      expect(controller[0].valueOf<String>(PassengerKey.fullName), 'Passenger 2');

      // Move out of bounds
      expect(() => controller.moveItem(-1, 0), throwsRangeError);
      expect(() => controller.moveItem(0, 10), throwsRangeError);

      // 4. Remove item at index 1
      controller.removeItemAt(1);
      expect(controller.length, 2);

      // Out of bounds remove
      expect(() => controller.removeItemAt(-1), throwsRangeError);
      expect(() => controller.removeItemAt(10), throwsRangeError);

      // 5. Remove item by ID
      final itemToRemove = controller.items[0];
      controller.removeItemById(itemToRemove.id);
      expect(controller.length, 1);
      expect(controller.items.any((i) => i.id == itemToRemove.id), isFalse);
    });

    test('setArrayField and setAndValidateArrayField update sub-form', () {
      controller.setArrayField(0, PassengerKey.fullName, 'Updated Name');
      expect(controller[0].valueOf<String>(PassengerKey.fullName), 'Updated Name');
      expect(controller.isDirty, isTrue);
      expect(controller.isValid, isTrue);

      // clearError: false & touch: false
      controller.setAndValidateArrayField(0, PassengerKey.passportNumber, 'AB');
      expect(controller[0].field(PassengerKey.passportNumber).error, isNotNull);

      controller.setArrayField(
        0,
        PassengerKey.passportNumber,
        'ABC',
        clearError: false,
        touch: false,
      );
      expect(controller[0].field(PassengerKey.passportNumber).error, isNotNull);

      // Valid update
      controller.setAndValidateArrayField(
        0,
        PassengerKey.passportNumber,
        'ABCD',
      );
      expect(controller[0].field(PassengerKey.passportNumber).error, isNull);

      // Argument & Range errors
      expect(
        () => controller.setArrayField(-1, PassengerKey.fullName, 'Err'),
        throwsRangeError,
      );
      expect(
        () => controller.setAndValidateArrayField(-1, PassengerKey.fullName, 'Err'),
        throwsRangeError,
      );
      expect(
        () => controller.setArrayField(0, PassengerKey.seatType, 'Err'),
        throwsArgumentError,
      );
      expect(
        () => controller.setAndValidateArrayField(0, PassengerKey.seatType, 'Err'),
        throwsArgumentError,
      );
    });

    test('validateArray checks items and array level rules', () {
      // Valid initial
      expect(controller.validateArray(), isTrue);

      // Add invalid item (empty required name)
      controller.addItem({
        PassengerKey.fullName: '',
        PassengerKey.passportNumber: 'VALID1',
      });
      expect(controller.validateArray(), isFalse);
      expect(controller[1].field(PassengerKey.fullName).showError, isTrue);

      // Fix item but violate unique passport
      controller.setArrayField(1, PassengerKey.fullName, 'P2');
      controller.setArrayField(1, PassengerKey.passportNumber, 'PASS1'); // duplicate of item 0

      expect(controller.validateArray(), isFalse);
      expect(controller.state.error?.code, NeatArrayValidators.codeUniqueBy);
    });

    test('submitForm handles valid, invalid, and exception flows', () async {
      var submitted = false;
      List<Map<PassengerKey, Object?>>? capturedValues;

      // 1. Invalid submission
      controller.addItem({
        PassengerKey.fullName: '',
        PassengerKey.passportNumber: '',
      });

      NeatValidationError? capturedArrayErr;
      List<Map<PassengerKey, NeatValidationError>>? capturedItemErrs;

      final successInvalid = await controller.submitForm(
        onSubmit: (values) async {
          submitted = true;
        },
        onError: (arrayErr, itemErrs) {
          capturedArrayErr = arrayErr;
          capturedItemErrs = itemErrs;
        },
      );

      expect(successInvalid, isFalse);
      expect(submitted, isFalse);
      expect(controller.submissionStatus, NeatSubmissionStatus.failure);
      expect(capturedItemErrs, isNotNull);

      // 2. Fix errors and valid submit
      controller.setArrayField(1, PassengerKey.fullName, 'Valid Name 2');
      controller.setArrayField(1, PassengerKey.passportNumber, 'PASS2');

      final successValid = await controller.submitForm(
        onSubmit: (values) async {
          submitted = true;
          capturedValues = values;
        },
      );

      expect(successValid, isTrue);
      expect(submitted, isTrue);
      expect(capturedValues?.length, 2);
      expect(controller.submissionStatus, NeatSubmissionStatus.success);

      // 3. Exception in onSubmit
      await expectLater(
        () => controller.submitForm(
          onSubmit: (values) async {
            throw Exception('Network failed');
          },
        ),
        throwsA(isA<Exception>()),
      );
      expect(controller.submissionStatus, NeatSubmissionStatus.failure);
    });

    test('resetArray, clearErrors, and dispose', () {
      controller.setAndValidateArrayField(0, PassengerKey.fullName, 'Changed');
      expect(controller.isDirty, isTrue);

      controller.resetArray();
      expect(controller[0].valueOf<String>(PassengerKey.fullName), 'Passenger 1');
      expect(controller.isDirty, isFalse);
      expect(controller.submissionStatus, NeatSubmissionStatus.idle);

      // clearErrors
      controller.setAndValidateArrayField(0, PassengerKey.passportNumber, 'a');
      expect(controller[0].field(PassengerKey.passportNumber).error, isNotNull);

      controller.clearErrors();
      expect(controller[0].field(PassengerKey.passportNumber).error, isNull);

      // dispose
      controller.dispose();
      expect(controller.isDisposed, isTrue);
      controller.addItem({}); // ignored after dispose
      expect(controller.length, 1);
    });
  });

  group('NeatFormArrayNotifierMixin (Riverpod integration)', () {
    test('executes all array mutations cleanly', () async {
      final notifier = _SampleArrayNotifier();

      expect(notifier.length, 1);
      expect(notifier.isEmpty, isFalse);
      expect(notifier.isNotEmpty, isTrue);
      expect(notifier.isDirty, isFalse);
      expect(notifier.isValid, isTrue);
      expect(notifier.values.length, 1);
      expect(notifier[0].valueOf<String>(PassengerKey.fullName), 'First');

      notifier.addItem({PassengerKey.fullName: 'Second'});
      expect(notifier.length, 2);

      notifier.insertItem(1, {PassengerKey.fullName: 'Middle'});
      notifier.insertItem(2, {PassengerKey.fullName: 'Fourth'});
      expect(notifier.length, 4);

      notifier.moveItem(0, 2);
      notifier.removeItemAt(0);
      expect(notifier.length, 3);

      final idToRemove = notifier.state.items[0].id;
      notifier.removeItemById(idToRemove);
      expect(notifier.length, 2);

      notifier.setArrayField(0, PassengerKey.fullName, 'Alex');
      expect(notifier.state[0].valueOf<String>(PassengerKey.fullName), 'Alex');
      expect(notifier.isDirty, isTrue);

      notifier.setAndValidateArrayField(0, PassengerKey.fullName, 'Alex Validated');
      expect(notifier.state[0].valueOf<String>(PassengerKey.fullName), 'Alex Validated');

      final isValid = notifier.validateArray();
      expect(isValid, isTrue);

      var submitted = false;
      final ok = await notifier.submitForm(
        onSubmit: (v) async => submitted = true,
      );
      expect(ok, isTrue);
      expect(submitted, isTrue);
      expect(notifier.submissionStatus, NeatSubmissionStatus.success);

      notifier.resetArray();
      expect(notifier.submissionStatus, NeatSubmissionStatus.idle);
      expect(notifier.isDirty, isFalse);
    });

    test('submitForm handles failure and exception', () async {
      final notifier = _SampleArrayNotifier();
      notifier.addItem({PassengerKey.fullName: ''}); // invalid required

      final ok = await notifier.submitForm(onSubmit: (v) async {});
      expect(ok, isFalse);
      expect(notifier.submissionStatus, NeatSubmissionStatus.failure);

      // Valid submit throwing exception
      notifier.setArrayField(1, PassengerKey.fullName, 'Fixed');
      await expectLater(
        () => notifier.submitForm(onSubmit: (v) async => throw Exception('err')),
        throwsA(isA<Exception>()),
      );
      expect(notifier.submissionStatus, NeatSubmissionStatus.failure);
    });
  });

  group('NeatFormArrayCubitMixin (BLoC / Cubit integration)', () {
    test('executes all cubit mutations cleanly', () async {
      final cubit = _SampleArrayCubit();

      expect(cubit.length, 1);
      expect(cubit.isEmpty, isFalse);
      expect(cubit.isNotEmpty, isTrue);
      expect(cubit.isDirty, isFalse);
      expect(cubit.isValid, isTrue);
      expect(cubit.values.length, 1);
      expect(cubit[0].valueOf<String>(PassengerKey.fullName), 'First');

      cubit.addItem({PassengerKey.fullName: 'Cubit 2'});
      expect(cubit.state.length, 2);

      cubit.insertItem(1, {PassengerKey.fullName: 'Cubit Mid'});
      cubit.insertItem(2, {PassengerKey.fullName: 'Cubit Fourth'});
      expect(cubit.state.length, 4);

      cubit.moveItem(0, 2);
      cubit.removeItemAt(0);
      expect(cubit.state.length, 3);

      final idToRemove = cubit.state.items[0].id;
      cubit.removeItemById(idToRemove);
      expect(cubit.state.length, 2);

      cubit.setArrayField(0, PassengerKey.fullName, 'Cubit Alex');
      expect(cubit.state[0].valueOf<String>(PassengerKey.fullName), 'Cubit Alex');
      expect(cubit.isDirty, isTrue);

      cubit.setAndValidateArrayField(0, PassengerKey.fullName, 'Cubit Validated');
      expect(cubit.state[0].valueOf<String>(PassengerKey.fullName), 'Cubit Validated');

      final isValid = cubit.validateArray();
      expect(isValid, isTrue);

      var submitted = false;
      final ok = await cubit.submitForm(
        onSubmit: (v) async => submitted = true,
      );
      expect(ok, isTrue);
      expect(submitted, isTrue);
      expect(cubit.submissionStatus, NeatSubmissionStatus.success);

      cubit.resetArray();
      expect(cubit.submissionStatus, NeatSubmissionStatus.idle);
      expect(cubit.isDirty, isFalse);
    });

    test('submitForm handles failure and exception', () async {
      final cubit = _SampleArrayCubit();
      cubit.addItem({PassengerKey.fullName: ''}); // invalid required

      final ok = await cubit.submitForm(onSubmit: (v) async {});
      expect(ok, isFalse);
      expect(cubit.submissionStatus, NeatSubmissionStatus.failure);

      // Valid submit throwing exception
      cubit.setArrayField(1, PassengerKey.fullName, 'Fixed');
      await expectLater(
        () => cubit.submitForm(onSubmit: (v) async => throw Exception('err')),
        throwsA(isA<Exception>()),
      );
      expect(cubit.submissionStatus, NeatSubmissionStatus.failure);
    });
  });
}

class _SampleArrayNotifier with NeatFormArrayNotifierMixin<PassengerKey> {
  NeatFormArrayState<PassengerKey> _state =
      NeatFormArrayState<PassengerKey>.fromValuesList([
    {PassengerKey.fullName: 'First', PassengerKey.passportNumber: 'P1'},
  ]);

  @override
  NeatFormArrayState<PassengerKey> get state => _state;

  @override
  set state(NeatFormArrayState<PassengerKey> value) => _state = value;

  @override
  Map<PassengerKey, NeatValidator<Object?>> get itemValidators => {
        PassengerKey.fullName: NeatValidators.required(),
      };
}

class _SampleArrayCubit with NeatFormArrayCubitMixin<PassengerKey> {
  NeatFormArrayState<PassengerKey> _state =
      NeatFormArrayState<PassengerKey>.fromValuesList([
    {PassengerKey.fullName: 'First', PassengerKey.passportNumber: 'P1'},
  ]);

  @override
  NeatFormArrayState<PassengerKey> get state => _state;

  @override
  void emit(NeatFormArrayState<PassengerKey> state) => _state = state;

  @override
  Map<PassengerKey, NeatValidator<Object?>> get itemValidators => {
        PassengerKey.fullName: NeatValidators.required(),
      };
}
