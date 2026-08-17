import 'package:flutter_test/flutter_test.dart';
import 'package:neat_form_devtools_extension/src/models/form_details.dart';
import 'package:neat_form_devtools_extension/src/models/form_event.dart';
import 'package:neat_form_devtools_extension/src/models/form_summary.dart';

void main() {
  group('DevTools Extension Models Serialization', () {
    test('FormSummary.fromJson parses correctly', () {
      final json = {
        'id': 'form_1',
        'name': 'LoginForm',
        'type': 'form',
        'fieldsCount': 3,
        'isValid': true,
        'isTouched': false,
        'status': 'idle',
        'createdAt': '2026-08-17T12:00:00.000Z',
      };

      final summary = FormSummary.fromJson(json);
      expect(summary.id, equals('form_1'));
      expect(summary.name, equals('LoginForm'));
      expect(summary.type, equals('form'));
      expect(summary.fieldsCount, equals(3));
      expect(summary.itemsCount, equals(0));
      expect(summary.isValid, isTrue);
      expect(summary.isTouched, isFalse);
      expect(summary.status, equals('idle'));
      expect(summary.isArray, isFalse);

      final arrayJson = {
        'id': 'array_1',
        'name': 'GuestArray',
        'type': 'array',
        'itemsCount': 5,
        'isValid': false,
        'isTouched': true,
        'status': 'submitting',
      };
      final arraySummary = FormSummary.fromJson(arrayJson);
      expect(arraySummary.isArray, isTrue);
      expect(arraySummary.itemsCount, equals(5));
      expect(arraySummary.isValid, isFalse);
    });

    test('FieldDetails and FormDetails parse complex JSON correctly', () {
      final json = {
        'id': 'form_123',
        'name': 'UserForm',
        'type': 'form',
        'isValid': true,
        'isTouched': true,
        'status': 'idle',
        'fields': {
          'email': {
            'key': 'email',
            'value': 'test@example.com',
            'initialValue': '',
            'isValid': true,
            'isInvalid': false,
            'isTouched': true,
            'isOptional': false,
            'isValidating': false,
            'isValidated': true,
            'showError': false,
            'errorMessage': null,
          },
          'password': {
            'key': 'password',
            'value': '123',
            'isValid': false,
            'isInvalid': true,
            'isTouched': true,
            'errorMessage': 'Too short',
            'errorCode': 'min_length',
            'errorParams': {'min': 6},
          },
        },
      };

      final details = FormDetails.fromJson(json);
      expect(details.id, equals('form_123'));
      expect(details.fields.length, equals(2));

      final email = details.fields['email']!;
      expect(email.key, equals('email'));
      expect(email.value, equals('test@example.com'));
      expect(email.isValid, isTrue);
      expect(email.isOptional, isFalse);

      final password = details.fields['password']!;
      expect(password.key, equals('password'));
      expect(password.value, equals('123'));
      expect(password.isValid, isFalse);
      expect(password.errorMessage, equals('Too short'));
      expect(password.errorCode, equals('min_length'));
      expect(password.errorParams?['min'], equals(6));
    });

    test('ArrayItemDetails and FormDetails parse dynamic array hierarchy correctly', () {
      final json = {
        'id': 'array_456',
        'name': 'CartArray',
        'type': 'array',
        'length': 1,
        'isValid': true,
        'isTouched': false,
        'status': 'idle',
        'error': 'Minimum 2 items required',
        'items': [
          {
            'id': 'item_1',
            'index': 0,
            'isValid': true,
            'isTouched': false,
            'fields': {
              'item_name': {
                'key': 'item_name',
                'value': 'MacBook Pro',
                'isValid': true,
                'isInvalid': false,
                'isTouched': false,
              },
            },
          },
        ],
      };

      final details = FormDetails.fromJson(json);
      expect(details.isArray, isTrue);
      expect(details.items.length, equals(1));
      expect(details.error, equals('Minimum 2 items required'));

      final item = details.items.first;
      expect(item.id, equals('item_1'));
      expect(item.index, equals(0));
      expect(item.fields['item_name']?.value, equals('MacBook Pro'));
    });

    test('FormEvent.fromJson and summary format correctly', () {
      final event1 = FormEvent.fromJson({
        'kind': 'form_registered',
        'formId': 'form_1',
        'name': 'TestForm',
      });
      expect(event1.summary, contains('Registered form: TestForm'));

      final event2 = FormEvent.fromJson({
        'kind': 'form_unregistered',
        'formId': 'form_1',
      });
      expect(event2.summary, contains('Disposed form: form_1'));

      final event3 = FormEvent.fromJson({
        'kind': 'form_updated',
        'formId': 'form_1',
        'isValid': true,
        'isTouched': false,
      });
      expect(event3.summary, contains('Updated state'));

      final event4 = FormEvent.fromJson({
        'kind': 'form_array_updated',
        'formId': 'array_1',
        'length': 3,
        'isValid': true,
      });
      expect(event4.summary, contains('Array updated'));

      final event5 = FormEvent.fromJson({
        'kind': 'submission_status_changed',
        'formId': 'form_1',
        'status': 'submitting',
      });
      expect(event5.summary, contains('Status changed -> submitting'));

      final customEvent = FormEvent.fromJson({
        'kind': 'custom_kind',
        'formId': 'form_1',
      });
      expect(customEvent.summary, contains('custom_kind'));
    });
  });
}
