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

      // Valid update with touch: false
      controller.setAndValidateArrayField(
        0,
        PassengerKey.passportNumber,
        'ABCD',
        touch: false,
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
      // Gracefully sets uninitialized field
      controller.setArrayField(0, PassengerKey.seatType, 'Economy');
      expect(controller[0].valueOf<String>(PassengerKey.seatType), 'Economy');
      controller.setAndValidateArrayField(0, PassengerKey.seatType, 'Business');
      expect(controller[0].valueOf<String>(PassengerKey.seatType), 'Business');
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

      // 4. Non-Exception error in onSubmit (catch (_))
      await expectLater(
        () => controller.submitForm(
          onSubmit: (values) async {
            throw StateError('raw state error');
          },
        ),
        throwsA(isA<StateError>()),
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

      await expectLater(
        () => notifier.submitForm(onSubmit: (v) async => throw StateError('err')),
        throwsA(isA<StateError>()),
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

      await expectLater(
        () => cubit.submitForm(onSubmit: (v) async => throw StateError('err')),
        throwsA(isA<StateError>()),
      );
      expect(cubit.submissionStatus, NeatSubmissionStatus.failure);
    });
  });

  group('NeatNestedFormArrayNotifierMixin (Nested Screen State)', () {
    test('operates all mutations on nested array form inside screen state', () async {
      final notifier = _SampleNestedArrayNotifier();

      expect(notifier.length, 1);
      expect(notifier.isEmpty, isFalse);
      expect(notifier.isNotEmpty, isTrue);
      expect(notifier.isValid, isTrue);
      expect(notifier.isDirty, isFalse);
      expect(notifier.values.length, 1);
      expect(notifier[0].valueOf<String>(PassengerKey.fullName), 'John Nested');

      notifier.addItem({PassengerKey.fullName: 'Jane Nested'});
      expect(notifier.length, 2);

      notifier.insertItem(1, {PassengerKey.fullName: 'Mid Nested'});
      expect(notifier.length, 3);

      notifier.moveItem(0, 2);
      notifier.removeItemAt(0);
      expect(notifier.length, 2);

      final idToRemove = notifier.state.passengers.items[0].id;
      notifier.removeItemById(idToRemove);
      expect(notifier.length, 1);

      notifier.setArrayField(0, PassengerKey.fullName, 'Alex Nested');
      expect(notifier.arrayState[0].valueOf<String>(PassengerKey.fullName), 'Alex Nested');
      expect(notifier.isDirty, isTrue);

      notifier.setAndValidateArrayField(0, PassengerKey.fullName, 'Alex Validated');
      expect(notifier.arrayState[0].valueOf<String>(PassengerKey.fullName), 'Alex Validated');

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

    test('submitForm handles failure and exception in nested notifier', () async {
      final notifier = _SampleNestedArrayNotifier();
      notifier.addItem({PassengerKey.fullName: ''});

      final ok = await notifier.submitForm(onSubmit: (v) async {});
      expect(ok, isFalse);
      expect(notifier.submissionStatus, NeatSubmissionStatus.failure);

      notifier.setArrayField(1, PassengerKey.fullName, 'Fixed');
      await expectLater(
        () => notifier.submitForm(onSubmit: (v) async => throw Exception('nested err')),
        throwsA(isA<Exception>()),
      );
      expect(notifier.submissionStatus, NeatSubmissionStatus.failure);

      await expectLater(
        () => notifier.submitForm(onSubmit: (v) async => throw StateError('nested err')),
        throwsA(isA<StateError>()),
      );
      expect(notifier.submissionStatus, NeatSubmissionStatus.failure);
    });
  });

  group('NeatNestedFormArrayCubitMixin (Nested Screen State)', () {
    test('operates all mutations on nested array form in cubit', () async {
      final cubit = _SampleNestedArrayCubit();

      expect(cubit.length, 1);
      expect(cubit.isEmpty, isFalse);
      expect(cubit.isNotEmpty, isTrue);
      expect(cubit.isValid, isTrue);
      expect(cubit.isDirty, isFalse);
      expect(cubit.values.length, 1);
      expect(cubit[0].valueOf<String>(PassengerKey.fullName), 'Cubit John Nested');

      cubit.addItem({PassengerKey.fullName: 'Cubit Jane Nested'});
      expect(cubit.length, 2);

      cubit.insertItem(1, {PassengerKey.fullName: 'Cubit Mid Nested'});
      expect(cubit.length, 3);

      cubit.moveItem(0, 2);
      cubit.removeItemAt(0);
      expect(cubit.length, 2);

      final idToRemove = cubit.state.passengers.items[0].id;
      cubit.removeItemById(idToRemove);
      expect(cubit.length, 1);

      cubit.setArrayField(0, PassengerKey.fullName, 'Cubit Alex Nested');
      expect(cubit.arrayState[0].valueOf<String>(PassengerKey.fullName), 'Cubit Alex Nested');
      expect(cubit.isDirty, isTrue);

      cubit.setAndValidateArrayField(0, PassengerKey.fullName, 'Cubit Alex Validated');
      expect(cubit.arrayState[0].valueOf<String>(PassengerKey.fullName), 'Cubit Alex Validated');

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

    test('submitForm handles failure and exception in nested cubit', () async {
      final cubit = _SampleNestedArrayCubit();
      cubit.addItem({PassengerKey.fullName: ''});

      final ok = await cubit.submitForm(onSubmit: (v) async {});
      expect(ok, isFalse);
      expect(cubit.submissionStatus, NeatSubmissionStatus.failure);

      cubit.setArrayField(1, PassengerKey.fullName, 'Fixed');
      await expectLater(
        () => cubit.submitForm(onSubmit: (v) async => throw Exception('nested cubit err')),
        throwsA(isA<Exception>()),
      );
      expect(cubit.submissionStatus, NeatSubmissionStatus.failure);

      await expectLater(
        () => cubit.submitForm(onSubmit: (v) async => throw StateError('nested cubit err')),
        throwsA(isA<StateError>()),
      );
      expect(cubit.submissionStatus, NeatSubmissionStatus.failure);
    });

    test('NeatFormArrayController CRUD helpers: removeWhere, clearItems, setItems, reorderItem', () {
      final controller = NeatFormArrayController<PassengerKey>(
        itemValidators: {
          PassengerKey.fullName: NeatValidators.required(),
          PassengerKey.passportNumber: NeatValidators.required(),
        },
      );

      controller.setItems([
        {PassengerKey.fullName: 'Alice', PassengerKey.passportNumber: 'A1'},
        {PassengerKey.fullName: 'Bob', PassengerKey.passportNumber: 'B1'},
        {PassengerKey.fullName: 'Charlie', PassengerKey.passportNumber: 'C1'},
      ]);
      expect(controller.length, 3);

      // reorderItem
      controller.reorderItem(0, 3);
      expect(controller.values[2][PassengerKey.fullName], 'Alice');

      // removeWhere
      controller.removeWhere((item) => item.form.valueOf<String>(PassengerKey.fullName) == 'Bob');
      expect(controller.length, 2);
      expect(controller.values.any((v) => v[PassengerKey.fullName] == 'Bob'), isFalse);

      // clearItems
      controller.clearItems();
      expect(controller.length, 0);
      expect(controller.state.isEmpty, isTrue);
    });

    test('NeatFormArrayController auto-populates templateKeys on addItem / insertItem', () {
      final controller = NeatFormArrayController<PassengerKey>(
        itemValidators: {
          PassengerKey.fullName: NeatValidators.required(),
          PassengerKey.passportNumber: NeatValidators.required(),
        },
      );

      // Calling addItem without initialValues
      controller.addItem();
      expect(controller.length, 1);
      // Ensure setting a field never crashes
      controller.setArrayField(0, PassengerKey.fullName, 'Alex');
      expect(controller[0].valueOf<String>(PassengerKey.fullName), 'Alex');

      // Calling insertItem
      controller.insertItem(0);
      expect(controller.length, 2);
      controller.setArrayField(0, PassengerKey.passportNumber, 'P99');
      expect(controller[0].valueOf<String>(PassengerKey.passportNumber), 'P99');
    });

    test('uniqueBy validator handles caseSensitive: false and trimming', () {
      final validator = NeatArrayValidators.uniqueBy<PassengerKey, String>(
        (form) => form.valueOf<String>(PassengerKey.passportNumber),
        caseSensitive: false,
        trim: true,
      );

      final stateDuplicateCase = NeatFormArrayState<PassengerKey>.fromValuesList([
        {PassengerKey.passportNumber: '  vn123  '},
        {PassengerKey.passportNumber: 'VN123'},
      ]);
      final error = validator(stateDuplicateCase);
      expect(error, isNotNull);
      expect(error?.code, NeatArrayValidators.codeUniqueBy);

      final stateUnique = NeatFormArrayState<PassengerKey>.fromValuesList([
        {PassengerKey.passportNumber: 'VN123'},
        {PassengerKey.passportNumber: 'VN456'},
        {PassengerKey.passportNumber: ''}, // ignored empty
        {PassengerKey.passportNumber: null}, // ignored null
      ]);
      expect(validator(stateUnique), isNull);
    });

    test('validateArray validates union of existing fields and itemValidators keys', () {
      final controller = NeatFormArrayController<PassengerKey>(
        initialItems: [
          {PassengerKey.fullName: 'Valid Name'}, // Missing passportNumber key
        ],
        itemValidators: {
          PassengerKey.fullName: NeatValidators.required(),
          PassengerKey.passportNumber: NeatValidators.required(message: 'Hộ chiếu bắt buộc'),
        },
      );

      final isValid = controller.validateArray();

      expect(isValid, isFalse);
      expect(controller[0].field(PassengerKey.passportNumber).errorMessage, 'Hộ chiếu bắt buộc');
    });

    test('validateArrayFieldAsync executes async validation with race-condition tokens and error handling', () async {
      final controller = NeatFormArrayController<PassengerKey>(
        initialItems: [
          {PassengerKey.passportNumber: 'P100'},
        ],
      );

      // 1. Success case
      await controller.validateArrayFieldAsync<String>(
        0,
        PassengerKey.passportNumber,
        (val) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return null;
        },
      );
      expect(controller[0].field(PassengerKey.passportNumber).isValid, isTrue);
      expect(controller[0].field(PassengerKey.passportNumber).isValidating, isFalse);

      // 2. Error returned
      await controller.validateArrayFieldAsync<String>(
        0,
        PassengerKey.passportNumber,
        (val) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return const NeatValidationError('passport_expired', message: 'Hộ chiếu đã hết hạn');
        },
      );
      expect(controller[0].field(PassengerKey.passportNumber).errorMessage, 'Hộ chiếu đã hết hạn');
      expect(controller[0].field(PassengerKey.passportNumber).isValidating, isFalse);

      // 3. Exception fallback
      await controller.validateArrayFieldAsync<String>(
        0,
        PassengerKey.passportNumber,
        (val) async => throw Exception('Network timeout'),
      );
      expect(controller[0].field(PassengerKey.passportNumber).isValidating, isFalse);

      // 4. Out of bounds index safety
      await controller.validateArrayFieldAsync<String>(
        99,
        PassengerKey.passportNumber,
        (val) async => null,
      );
      expect(controller.length, 1);
    });

    test('NeatFormArrayState isTouched getter reflects touch status across items', () {
      final controller = NeatFormArrayController<PassengerKey>(
        initialItems: [
          {PassengerKey.fullName: 'A'},
          {PassengerKey.fullName: 'B'},
        ],
      );
      expect(controller.state.isTouched, isFalse);

      controller.setArrayField(1, PassengerKey.fullName, 'B_touched', touch: true);
      expect(controller.state.isTouched, isTrue);
    });

    test('NeatFormArrayNotifierMixin & CubitMixin execute removeWhere, clearItems, setItems', () {
      final notifier = _SampleArrayNotifier();
      notifier.setItems([
        {PassengerKey.fullName: 'N1'},
        {PassengerKey.fullName: 'N2'},
      ]);
      expect(notifier.length, 2);
      notifier.removeWhere((i) => i.form.valueOf<String>(PassengerKey.fullName) == 'N1');
      expect(notifier.length, 1);
      notifier.clearItems();
      expect(notifier.length, 0);

      final cubit = _SampleArrayCubit();
      cubit.setItems([
        {PassengerKey.fullName: 'C1'},
        {PassengerKey.fullName: 'C2'},
      ]);
      expect(cubit.length, 2);
      cubit.removeWhere((i) => i.form.valueOf<String>(PassengerKey.fullName) == 'C1');
      expect(cubit.length, 1);
      cubit.clearItems();
      expect(cubit.length, 0);
    });

    test('NeatNestedFormArrayNotifierMixin & NestedCubitMixin execute removeWhere, clearItems, setItems', () {
      final nestedNotifier = _SampleNestedArrayNotifier();
      nestedNotifier.setItems([
        {PassengerKey.fullName: 'NN1'},
        {PassengerKey.fullName: 'NN2'},
      ]);
      expect(nestedNotifier.length, 2);
      nestedNotifier.removeWhere((i) => i.form.valueOf<String>(PassengerKey.fullName) == 'NN1');
      expect(nestedNotifier.length, 1);
      nestedNotifier.clearItems();
      expect(nestedNotifier.length, 0);

      final nestedCubit = _SampleNestedArrayCubit();
      nestedCubit.setItems([
        {PassengerKey.fullName: 'NC1'},
        {PassengerKey.fullName: 'NC2'},
      ]);
      expect(nestedCubit.length, 2);
      nestedCubit.removeWhere((i) => i.form.valueOf<String>(PassengerKey.fullName) == 'NC1');
      expect(nestedCubit.length, 1);
      nestedCubit.clearItems();
      expect(nestedCubit.length, 0);
    });

    test('submitForm invokes onError callback across controller and all mixins', () async {
      // 1. Controller onError
      final controller = NeatFormArrayController<PassengerKey>(
        initialItems: [{PassengerKey.fullName: ''}],
        itemValidators: {PassengerKey.fullName: NeatValidators.required()},
      );
      bool controllerErrorCalled = false;
      await controller.submitForm(
        onSubmit: (v) async {},
        onError: (arrayErr, itemErrs) {
          controllerErrorCalled = true;
          expect(itemErrs.first[PassengerKey.fullName], isNotNull);
        },
      );
      expect(controllerErrorCalled, isTrue);

      // 2. Notifier onError
      final notifier = _SampleArrayNotifier();
      notifier.setArrayField(0, PassengerKey.fullName, '');
      bool notifierErrorCalled = false;
      await notifier.submitForm(
        onSubmit: (v) async {},
        onError: (arrayErr, itemErrs) {
          notifierErrorCalled = true;
          expect(itemErrs.first[PassengerKey.fullName], isNotNull);
        },
      );
      expect(notifierErrorCalled, isTrue);

      // 3. Cubit onError
      final cubit = _SampleArrayCubit();
      cubit.setArrayField(0, PassengerKey.fullName, '');
      bool cubitErrorCalled = false;
      await cubit.submitForm(
        onSubmit: (v) async {},
        onError: (arrayErr, itemErrs) {
          cubitErrorCalled = true;
          expect(itemErrs.first[PassengerKey.fullName], isNotNull);
        },
      );
      expect(cubitErrorCalled, isTrue);

      // 4. Nested Notifier onError
      final nestedNotifier = _SampleNestedArrayNotifier();
      nestedNotifier.setArrayField(0, PassengerKey.fullName, '');
      bool nestedNotifierErrorCalled = false;
      await nestedNotifier.submitForm(
        onSubmit: (v) async {},
        onError: (arrayErr, itemErrs) {
          nestedNotifierErrorCalled = true;
          expect(itemErrs.first[PassengerKey.fullName], isNotNull);
        },
      );
      expect(nestedNotifierErrorCalled, isTrue);

      // 5. Nested Cubit onError
      final nestedCubit = _SampleNestedArrayCubit();
      nestedCubit.setArrayField(0, PassengerKey.fullName, '');
      bool nestedCubitErrorCalled = false;
      await nestedCubit.submitForm(
        onSubmit: (v) async {},
        onError: (arrayErr, itemErrs) {
          nestedCubitErrorCalled = true;
          expect(itemErrs.first[PassengerKey.fullName], isNotNull);
        },
      );
      expect(nestedCubitErrorCalled, isTrue);
    });
  });
}

class _SampleNestedScreenState {
  _SampleNestedScreenState({
    required this.passengers,
    this.screenTitle = 'Booking',
  });

  final NeatFormArrayState<PassengerKey> passengers;
  final String screenTitle;

  _SampleNestedScreenState copyWith({
    NeatFormArrayState<PassengerKey>? passengers,
    String? screenTitle,
  }) {
    return _SampleNestedScreenState(
      passengers: passengers ?? this.passengers,
      screenTitle: screenTitle ?? this.screenTitle,
    );
  }
}

class _SampleNestedArrayNotifier
    with NeatNestedFormArrayNotifierMixin<_SampleNestedScreenState, PassengerKey> {
  _SampleNestedScreenState _state = _SampleNestedScreenState(
    passengers: NeatFormArrayState<PassengerKey>.fromValuesList([
      {PassengerKey.fullName: 'John Nested', PassengerKey.passportNumber: 'PASS_N1'},
    ]),
  );

  @override
  _SampleNestedScreenState get state => _state;

  @override
  set state(_SampleNestedScreenState value) => _state = value;

  @override
  NeatFormArrayState<PassengerKey> getArrayForm(_SampleNestedScreenState state) =>
      state.passengers;

  @override
  _SampleNestedScreenState updateArrayForm(
    _SampleNestedScreenState state,
    NeatFormArrayState<PassengerKey> arrayForm,
  ) =>
      state.copyWith(passengers: arrayForm);

  @override
  Map<PassengerKey, NeatValidator<Object?>> get itemValidators => {
        PassengerKey.fullName: NeatValidators.required(),
      };
}

class _SampleNestedArrayCubit
    with NeatNestedFormArrayCubitMixin<_SampleNestedScreenState, PassengerKey> {
  _SampleNestedScreenState _state = _SampleNestedScreenState(
    passengers: NeatFormArrayState<PassengerKey>.fromValuesList([
      {PassengerKey.fullName: 'Cubit John Nested', PassengerKey.passportNumber: 'CUBIT_N1'},
    ]),
  );

  @override
  _SampleNestedScreenState get state => _state;

  @override
  void emit(_SampleNestedScreenState state) => _state = state;

  @override
  NeatFormArrayState<PassengerKey> getArrayForm(_SampleNestedScreenState state) =>
      state.passengers;

  @override
  _SampleNestedScreenState updateArrayForm(
    _SampleNestedScreenState state,
    NeatFormArrayState<PassengerKey> arrayForm,
  ) =>
      state.copyWith(passengers: arrayForm);

  @override
  Map<PassengerKey, NeatValidator<Object?>> get itemValidators => {
        PassengerKey.fullName: NeatValidators.required(),
      };
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
