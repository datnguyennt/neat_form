import 'package:flutter_test/flutter_test.dart';
import 'package:neat_form/neat_form.dart';

enum LoginFormKey { email, password, age, terms, website, phone }

enum ItemKey { name, price, date }

void main() {
  setUp(() {
    NeatFormDevToolsRegistry.instance.clear();
  });

  tearDown(() {
    NeatFormDevToolsRegistry.instance.clear();
  });

  group('NeatFormDevToolsRegistry - Core Functionality', () {
    test('registers and retrieves active forms summary', () {
      final registry = NeatFormDevToolsRegistry.instance;

      final formCtrl = NeatFormController<LoginFormKey>.fromValues(
        initialValues: {
          LoginFormKey.email: 'test@example.com',
          LoginFormKey.password: '123456',
        },
        debugName: 'CustomLoginForm',
      );

      final arrayCtrl = NeatFormArrayController<ItemKey>(
        initialItems: [
          {ItemKey.name: 'Item 1', ItemKey.price: 100},
        ],
        debugName: 'CartItems',
      );

      final activeForms = registry.activeForms;
      expect(activeForms.length, equals(2));

      final formEntry = activeForms.firstWhere((f) => f['name'] == 'CustomLoginForm');
      expect(formEntry['type'], equals('form'));
      expect(formEntry['fieldsCount'], equals(2));
      expect(formEntry['status'], equals('idle'));

      final arrayEntry = activeForms.firstWhere((f) => f['name'] == 'CartItems');
      expect(arrayEntry['type'], equals('array'));
      expect(arrayEntry['itemsCount'], equals(1));

      formCtrl.dispose();
      arrayCtrl.dispose();
    });

    test('getFormDetails returns deep serialized fields for standard form', () {
      final registry = NeatFormDevToolsRegistry.instance;

      final formCtrl = NeatFormController<LoginFormKey>.fromValues(
        initialValues: {
          LoginFormKey.email: 'user@domain.com',
          LoginFormKey.password: 'pass',
        },
        validators: {
          LoginFormKey.email: NeatValidators.email(),
          LoginFormKey.password: NeatValidators.minLength(6, message: 'Too short'),
        },
      );

      formCtrl.validateForm();
      final formId = formCtrl.devToolsFormId!;

      final details = registry.getFormDetails(formId);
      expect(details, isNotNull);
      expect(details!['id'], equals(formId));
      expect(details['type'], equals('form'));
      expect(details['isValid'], isFalse);

      final fields = details['fields'] as Map<String, dynamic>;
      expect(fields['email']['isValid'], isTrue);
      expect(fields['email']['value'], equals('user@domain.com'));

      expect(fields['password']['isValid'], isFalse);
      expect(fields['password']['errorMessage'], equals('Too short'));
      expect(fields['password']['errorCode'], equals(NeatValidators.codeMinLength));

      formCtrl.dispose();
      expect(registry.getFormDetails(formId), isNull);
    });

    test('getFormDetails returns deep serialized items for dynamic form array', () {
      final registry = NeatFormDevToolsRegistry.instance;

      final arrayCtrl = NeatFormArrayController<ItemKey>(
        initialItems: [
          {ItemKey.name: 'Item A', ItemKey.price: 50},
          {ItemKey.name: 'Item B', ItemKey.price: 150},
        ],
        itemValidators: {
          ItemKey.name: NeatValidators.required(),
        },
      );

      final formId = arrayCtrl.devToolsFormId!;
      final details = registry.getFormDetails(formId);

      expect(details, isNotNull);
      expect(details!['type'], equals('array'));
      expect(details['length'], equals(2));

      final items = details['items'] as List<dynamic>;
      expect(items.length, equals(2));
      expect(items[0]['fields']['name']['value'], equals('Item A'));
      expect(items[1]['fields']['price']['value'], equals(150));

      arrayCtrl.dispose();
      expect(registry.getFormDetails(formId), isNull);
    });

    test('setFieldValue updates and validates field remotely', () {
      final registry = NeatFormDevToolsRegistry.instance;

      final formCtrl = NeatFormController<LoginFormKey>.fromValues(
        initialValues: {
          LoginFormKey.email: 'initial@domain.com',
          LoginFormKey.password: 'initial_pwd',
        },
        validators: {
          LoginFormKey.email: NeatValidators.email(message: 'Invalid email'),
        },
      );

      final formId = formCtrl.devToolsFormId!;

      // Update email with valid value
      final success1 = registry.setFieldValue(formId, 'email', 'updated@domain.com');
      expect(success1, isTrue);
      expect(formCtrl.field(LoginFormKey.email).value, equals('updated@domain.com'));
      expect(formCtrl.field(LoginFormKey.email).isValid, isTrue);

      // Update email with invalid value
      final success2 = registry.setFieldValue(formId, 'email', 'invalid_string');
      expect(success2, isTrue);
      expect(formCtrl.field(LoginFormKey.email).isValid, isFalse);
      expect(formCtrl.field(LoginFormKey.email).errorMessage, equals('Invalid email'));

      // Non-existing field or form
      expect(registry.setFieldValue(formId, 'non_existent_key', 'val'), isFalse);
      expect(registry.setFieldValue('invalid_form_id', 'email', 'val'), isFalse);

      formCtrl.dispose();
    });

    test('validateForm and resetForm execute cleanly on standard form', () {
      final registry = NeatFormDevToolsRegistry.instance;

      final formCtrl = NeatFormController<LoginFormKey>.fromValues(
        initialValues: {
          LoginFormKey.email: '',
        },
        validators: {
          LoginFormKey.email: NeatValidators.required(),
        },
      );

      final formId = formCtrl.devToolsFormId!;
      expect(formCtrl.field(LoginFormKey.email).isValidated, isFalse);

      // Trigger remote validation
      final valSuccess = registry.validateForm(formId);
      expect(valSuccess, isTrue);
      expect(formCtrl.field(LoginFormKey.email).isValidated, isTrue);
      expect(formCtrl.field(LoginFormKey.email).isValid, isFalse);

      // Trigger remote reset
      final resetSuccess = registry.resetForm(formId);
      expect(resetSuccess, isTrue);
      expect(formCtrl.field(LoginFormKey.email).isValidated, isFalse);

      formCtrl.dispose();
    });

    test('validateForm and resetForm execute cleanly on dynamic array', () {
      final registry = NeatFormDevToolsRegistry.instance;

      final arrayCtrl = NeatFormArrayController<ItemKey>(
        initialItems: [
          {ItemKey.name: ''},
        ],
        itemValidators: {
          ItemKey.name: NeatValidators.required(),
        },
      );

      final formId = arrayCtrl.devToolsFormId!;

      // Validate
      expect(registry.validateForm(formId), isTrue);
      expect(arrayCtrl.isValid, isFalse);

      // Reset
      expect(registry.resetForm(formId), isTrue);

      arrayCtrl.dispose();
    });

    test('autofillMockData generates smart mock values across standard and array forms', () {
      final registry = NeatFormDevToolsRegistry.instance;

      final formCtrl = NeatFormController<LoginFormKey>.fromValues(
        initialValues: {
          LoginFormKey.email: '',
          LoginFormKey.password: '',
          LoginFormKey.age: 0,
          LoginFormKey.terms: false,
          LoginFormKey.website: '',
          LoginFormKey.phone: '',
        },
        validators: {
          LoginFormKey.email: NeatValidators.email(),
          LoginFormKey.password: NeatValidators.minLength(6),
        },
      );

      final formId = formCtrl.devToolsFormId!;
      expect(registry.autofillMockData(formId), isTrue);

      expect(formCtrl.valueOf(LoginFormKey.email), equals('test.user@example.com'));
      expect(formCtrl.valueOf(LoginFormKey.password), equals('Secret@123456'));
      expect(formCtrl.valueOf(LoginFormKey.age), equals(25));
      expect(formCtrl.valueOf(LoginFormKey.terms), isTrue);
      expect(formCtrl.valueOf(LoginFormKey.website), equals('https://example.com'));
      expect(formCtrl.valueOf(LoginFormKey.phone), equals('0901234567'));
      expect(formCtrl.isValid, isTrue);

      // Test boundary mock generation
      expect(registry.autofillMockData(formId, mode: 'boundary'), isTrue);
      expect(formCtrl.valueOf(LoginFormKey.email), equals('invalid-email-format'));
      expect(formCtrl.valueOf(LoginFormKey.password), equals('123'));
      expect(formCtrl.valueOf(LoginFormKey.age), equals(-10));
      expect(formCtrl.valueOf(LoginFormKey.terms), isFalse);
      expect(formCtrl.valueOf(LoginFormKey.website), equals('htt://broken-url'));
      expect(formCtrl.valueOf(LoginFormKey.phone), equals('abc-not-a-number'));

      // Test importJsonState on standard form
      expect(
        registry.importJsonState(formId, {
          'email': 'custom@domain.com',
          'age': 30,
        }),
        isTrue,
      );
      expect(formCtrl.valueOf(LoginFormKey.email), equals('custom@domain.com'));
      expect(formCtrl.valueOf(LoginFormKey.age), equals(30));

      final emptyArrayCtrl = NeatFormArrayController<ItemKey>(
        itemValidators: {ItemKey.name: NeatValidators.required()},
      );
      final arrayId = emptyArrayCtrl.devToolsFormId!;
      expect(emptyArrayCtrl.isEmpty, isTrue);

      expect(registry.autofillMockData(arrayId), isTrue);
      expect(emptyArrayCtrl.length, equals(1));
      expect(emptyArrayCtrl.items.first.form.valueOf(ItemKey.name), equals('Nguyen Van Test'));

      expect(registry.autofillMockData(arrayId, mode: 'boundary'), isTrue);
      expect(emptyArrayCtrl.items.first.form.valueOf(ItemKey.name), equals(''));

      // Test importJsonState on dynamic array
      expect(
        registry.importJsonState(arrayId, {
          'items': [
            {'name': 'Item Alpha'},
            {
              'fields': {'name': 'Item Beta'}
            },
          ],
        }),
        isTrue,
      );
      expect(emptyArrayCtrl.length, equals(2));
      expect(emptyArrayCtrl.items[0].form.valueOf(ItemKey.name), equals('Item Alpha'));
      expect(emptyArrayCtrl.items[1].form.valueOf(ItemKey.name), equals('Item Beta'));

      // Test non-existing formId
      expect(registry.autofillMockData('unknown_id'), isFalse);
      expect(registry.importJsonState('unknown_id', {}), isFalse);

      formCtrl.dispose();
      emptyArrayCtrl.dispose();
    });

    test('unregister and clear remove references cleanly', () {
      final registry = NeatFormDevToolsRegistry.instance;

      final ctrl1 = NeatFormController<LoginFormKey>.fromValues(initialValues: {});
      final ctrl2 = NeatFormController<LoginFormKey>.fromValues(initialValues: {});

      expect(registry.activeForms.length, equals(2));

      registry.unregister(ctrl1.devToolsFormId);
      expect(registry.activeForms.length, equals(1));

      registry.clear();
      expect(registry.activeForms.isEmpty, isTrue);

      ctrl1.dispose();
      ctrl2.dispose();
    });
  });

  group('NeatFormDevToolsBridge & Controller Lifecycle Events', () {
    test('NeatFormDevToolsBridge.init and postEvent execute without exception', () {
      expect(() => NeatFormDevToolsBridge.init(), returnsNormally);
      expect(
        () => NeatFormDevToolsBridge.postEvent('custom_event', {'test': 123}),
        returnsNormally,
      );
    });

    test('Controller updates post events and updates state properly', () {
      final formCtrl = NeatFormController<LoginFormKey>.fromValues(
        initialValues: {LoginFormKey.email: 'first@mail.com'},
        debugName: 'MyTestForm',
      );

      expect(formCtrl.debugName, equals('MyTestForm'));
      expect(formCtrl.devToolsFormId, isNotNull);

      formCtrl.setField(LoginFormKey.email, 'second@mail.com');
      expect(formCtrl.valueOf(LoginFormKey.email), equals('second@mail.com'));

      formCtrl.updateSubmissionStatus(NeatSubmissionStatus.submitting);
      expect(formCtrl.submissionStatus, equals(NeatSubmissionStatus.submitting));

      final arrayCtrl = NeatFormArrayController<ItemKey>(
        initialItems: [
          {ItemKey.name: 'Item 1'},
        ],
        debugName: 'MyArrayForm',
      );

      expect(arrayCtrl.debugName, equals('MyArrayForm'));
      expect(arrayCtrl.devToolsFormId, isNotNull);

      arrayCtrl.addItem({ItemKey.name: 'Item 2'});
      expect(arrayCtrl.length, equals(2));

      formCtrl.dispose();
      arrayCtrl.dispose();

      expect(formCtrl.devToolsFormId, isNull);
      expect(arrayCtrl.devToolsFormId, isNull);
    });

    test('handleServiceExtensionCall routes and executes all RPC methods correctly', () async {
      final formCtrl = NeatFormController<LoginFormKey>.fromValues(
        initialValues: {
          LoginFormKey.email: 'dev@test.com',
          LoginFormKey.password: '123456',
        },
        validators: {
          LoginFormKey.email: NeatValidators.email(),
        },
      );

      final formId = formCtrl.devToolsFormId!;

      // 1. ext.neat_form.getForms
      final formsRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.getForms',
        {},
      );
      expect(formsRes.result, contains(formId));

      // 2. ext.neat_form.getFormDetails
      final detailsRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.getFormDetails',
        {'formId': formId},
      );
      expect(detailsRes.result, contains('dev@test.com'));

      // Error: missing formId
      final missingDetailsRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.getFormDetails',
        {},
      );
      expect(missingDetailsRes.errorCode, isNotNull);

      // Error: formId not found
      final notFoundDetailsRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.getFormDetails',
        {'formId': 'non_existent_id'},
      );
      expect(notFoundDetailsRes.errorCode, isNotNull);

      // 3. ext.neat_form.setFieldValue
      final setValRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.setFieldValue',
        {'formId': formId, 'key': 'email', 'value': 'new_dev@test.com'},
      );
      expect(setValRes.result, contains('"success":true'));
      expect(formCtrl.valueOf(LoginFormKey.email), equals('new_dev@test.com'));

      // setFieldValue with json object/array string
      await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.setFieldValue',
        {'formId': formId, 'key': 'email', 'value': '{"valid": true}'},
      );

      // Error: missing params
      final missingSetRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.setFieldValue',
        {'formId': formId},
      );
      expect(missingSetRes.errorCode, isNotNull);

      // Error: failed to update field
      final failedSetRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.setFieldValue',
        {'formId': formId, 'key': 'unknown_field', 'value': 'val'},
      );
      expect(failedSetRes.errorCode, isNotNull);

      // 4. ext.neat_form.validateForm
      final valRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.validateForm',
        {'formId': formId},
      );
      expect(valRes.result, contains('"success":true'));

      final missingValRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.validateForm',
        {},
      );
      expect(missingValRes.errorCode, isNotNull);

      // 5. ext.neat_form.resetForm
      final resetRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.resetForm',
        {'formId': formId},
      );
      expect(resetRes.result, contains('"success":true'));

      final missingResetRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.resetForm',
        {},
      );
      expect(missingResetRes.errorCode, isNotNull);

      // 6. ext.neat_form.autofillMock (valid & boundary)
      final mockRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.autofillMock',
        {'formId': formId, 'mode': 'valid'},
      );
      expect(mockRes.result, contains('"success":true'));

      final mockBoundaryRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.autofillMock',
        {'formId': formId, 'mode': 'boundary'},
      );
      expect(mockBoundaryRes.result, contains('"success":true'));
      expect(formCtrl.valueOf(LoginFormKey.email), equals('invalid-email-format'));

      final missingMockRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.autofillMock',
        {},
      );
      expect(missingMockRes.errorCode, isNotNull);

      // 7. ext.neat_form.importState
      final importRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.importState',
        {'formId': formId, 'values': '{"email": "imported@domain.com"}'},
      );
      expect(importRes.result, contains('"success":true'));
      expect(formCtrl.valueOf(LoginFormKey.email), equals('imported@domain.com'));

      // Error: missing params for importState
      final missingImportRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.importState',
        {},
      );
      expect(missingImportRes.errorCode, isNotNull);

      // Error: malformed json for importState
      final malformedImportRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.importState',
        {'formId': formId, 'values': 'not_json'},
      );
      expect(malformedImportRes.errorCode, isNotNull);

      // Error: non-map json for importState
      final nonMapImportRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.importState',
        {'formId': formId, 'values': '["list_not_map"]'},
      );
      expect(nonMapImportRes.errorCode, isNotNull);

      // 8. Unknown method
      final unknownRes = await NeatFormDevToolsBridge.handleServiceExtensionCall(
        'ext.neat_form.unknown',
        {},
      );
      expect(unknownRes.errorCode, isNotNull);

      formCtrl.dispose();
    });
  });
}
