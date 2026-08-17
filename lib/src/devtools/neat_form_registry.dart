import 'package:neat_form/src/form_array.dart';
import 'package:neat_form/src/form_controller.dart';

/// Metadata entry holding a weak reference to a registered form or form array.
class NeatFormDevToolsEntry {
  /// Creates a [NeatFormDevToolsEntry].
  NeatFormDevToolsEntry({
    required this.id,
    required this.name,
    required this.type,
    required Object target,
    required this.createdAt,
  }) : _targetRef = WeakReference(target);

  /// Unique identifier of this form instance.
  final String id;

  /// Human-readable debug name.
  final String name;

  /// Form type ('form' or 'array').
  final String type;

  /// Creation timestamp.
  final DateTime createdAt;

  final WeakReference<Object> _targetRef;

  /// The live target controller, or null if garbage-collected.
  Object? get target => _targetRef.target;

  /// True if the target has been garbage-collected or disposed.
  bool get isDisposed => target == null;
}

/// Registry that tracks all active [NeatFormController] and [NeatFormArrayController]
/// instances for Flutter DevTools inspection.
///
/// Uses [WeakReference] to prevent holding memory or causing memory leaks.
class NeatFormDevToolsRegistry {
  NeatFormDevToolsRegistry._();

  /// Global singleton instance.
  static final NeatFormDevToolsRegistry instance = NeatFormDevToolsRegistry._();

  final Map<String, NeatFormDevToolsEntry> _entries = {};
  int _idCounter = 0;

  /// Registers a [NeatFormController] and returns its assigned ID.
  String registerController<K>(
    NeatFormController<K> controller, {
    String? debugName,
  }) {
    _cleanupDisposed();
    _idCounter++;
    final formId = 'form_${_idCounter}_${controller.hashCode.toRadixString(16)}';
    final name = debugName ?? 'Form #$_idCounter ($K)';

    _entries[formId] = NeatFormDevToolsEntry(
      id: formId,
      name: name,
      type: 'form',
      target: controller,
      createdAt: DateTime.now(),
    );

    return formId;
  }

  /// Registers a [NeatFormArrayController] and returns its assigned ID.
  String registerArrayController<K>(
    NeatFormArrayController<K> controller, {
    String? debugName,
  }) {
    _cleanupDisposed();
    _idCounter++;
    final formId = 'array_${_idCounter}_${controller.hashCode.toRadixString(16)}';
    final name = debugName ?? 'FormArray #$_idCounter ($K)';

    _entries[formId] = NeatFormDevToolsEntry(
      id: formId,
      name: name,
      type: 'array',
      target: controller,
      createdAt: DateTime.now(),
    );

    return formId;
  }

  /// Unregisters an instance by its [formId].
  void unregister(String? formId) {
    if (formId == null) return;
    _entries.remove(formId);
  }

  /// Clears all entries from the registry (primarily for testing).
  void clear() {
    _entries.clear();
    _idCounter = 0;
  }

  /// Returns summary information for all active, non-disposed forms.
  List<Map<String, dynamic>> get activeForms {
    _cleanupDisposed();
    final list = <Map<String, dynamic>>[];

    for (final entry in _entries.values) {
      final target = entry.target;
      if (target == null) continue;

      if (target is NeatFormController) {
        final state = target.state;
        list.add({
          'id': entry.id,
          'name': entry.name,
          'type': 'form',
          'fieldsCount': state.fields.length,
          'isValid': state.isValid,
          'isTouched': state.isTouched,
          'status': state.submissionStatus.name,
          'createdAt': entry.createdAt.toIso8601String(),
        });
      } else if (target is NeatFormArrayController) {
        final state = target.state;
        list.add({
          'id': entry.id,
          'name': entry.name,
          'type': 'array',
          'itemsCount': state.length,
          'isValid': state.isValid,
          'isTouched': state.isTouched,
          'status': state.status.name,
          'createdAt': entry.createdAt.toIso8601String(),
        });
      }
    }

    return list;
  }

  /// Retrieves deep details and serialized field states of a specific [formId].
  Map<String, dynamic>? getFormDetails(String formId) {
    final entry = _entries[formId];
    if (entry == null) return null;

    final target = entry.target;
    if (target == null) {
      _entries.remove(formId);
      return null;
    }

    if (target is NeatFormController) {
      final state = target.state;
      final fieldsData = <String, dynamic>{};

      for (final MapEntry(:key, :value) in state.fields.entries) {
        final keyStr = _keyToString(key);
        fieldsData[keyStr] = {
          'key': keyStr,
          'value': value.value,
          'initialValue': value.initialValue,
          'isValid': value.isValid,
          'isInvalid': value.isInvalid,
          'isTouched': value.isTouched,
          'isOptional': value.isOptional,
          'isValidating': value.isValidating,
          'isValidated': value.isValidated,
          'showError': value.showError,
          'errorMessage': value.errorMessage,
          'errorCode': value.error?.code,
          'errorParams': value.error?.params,
        };
      }

      return {
        'id': entry.id,
        'name': entry.name,
        'type': 'form',
        'isValid': state.isValid,
        'isTouched': state.isTouched,
        'status': state.submissionStatus.name,
        'fields': fieldsData,
        'createdAt': entry.createdAt.toIso8601String(),
      };
    } else if (target is NeatFormArrayController) {
      final state = target.state;
      final itemsData = <Map<String, dynamic>>[];

      for (var i = 0; i < state.items.length; i++) {
        final item = state.items[i];
        final itemFields = <String, dynamic>{};

        for (final MapEntry(key: fKey, value: fVal)
            in item.form.fields.entries) {
          final keyStr = _keyToString(fKey);
          itemFields[keyStr] = {
            'key': keyStr,
            'value': fVal.value,
            'isValid': fVal.isValid,
            'isTouched': fVal.isTouched,
            'errorMessage': fVal.errorMessage,
            'errorCode': fVal.error?.code,
          };
        }

        itemsData.add({
          'id': item.id,
          'index': i,
          'isValid': item.form.isValid,
          'isTouched': item.form.isTouched,
          'fields': itemFields,
        });
      }

      return {
        'id': entry.id,
        'name': entry.name,
        'type': 'array',
        'length': state.length,
        'isValid': state.isValid,
        'isTouched': state.isTouched,
        'status': state.status.name,
        'error': state.error?.message,
        'items': itemsData,
        'createdAt': entry.createdAt.toIso8601String(),
      };
    }

    return null;
  }

  /// Sets a field value remotely on the target [formId].
  bool setFieldValue(String formId, String keyName, Object? value) {
    final entry = _entries[formId];
    if (entry == null) return false;

    final target = entry.target;
    if (target is NeatFormController) {
      final matchingKey = _findMatchingKey(target.state.fields.keys, keyName);
      if (matchingKey != null) {
        target.setAndValidateField(matchingKey, value);
        return true;
      }
    }
    return false;
  }

  /// Triggers form validation on [formId].
  bool validateForm(String formId) {
    final entry = _entries[formId];
    if (entry == null) return false;

    final target = entry.target;
    if (target is NeatFormController) {
      target.validateForm();
      return true;
    } else if (target is NeatFormArrayController) {
      target.validateArray();
      return true;
    }
    return false;
  }

  /// Resets the form on [formId].
  bool resetForm(String formId) {
    final entry = _entries[formId];
    if (entry == null) return false;

    final target = entry.target;
    if (target is NeatFormController) {
      target.resetForm();
      return true;
    } else if (target is NeatFormArrayController) {
      target.resetArray();
      return true;
    }
    return false;
  }

  /// Automatically fills mock test data into all fields of [formId].
  ///
  /// [mode] can be `'valid'` (standard valid inputs) or `'boundary'` (invalid / edge case inputs).
  bool autofillMockData(String formId, {String mode = 'valid'}) {
    final entry = _entries[formId];
    if (entry == null) return false;

    final isBoundary = mode == 'boundary';
    final target = entry.target;
    if (target is NeatFormController) {
      for (final key in target.state.fields.keys) {
        final keyStr = _keyToString(key).toLowerCase();
        final mockValue = _generateMockValue(keyStr, isBoundary: isBoundary);
        target.setAndValidateField(key, mockValue);
      }
      return true;
    } else if (target is NeatFormArrayController) {
      if (target.state.isEmpty) {
        target.addItem();
      }
      for (var i = 0; i < target.state.items.length; i++) {
        final item = target.state.items[i];
        for (final key in item.form.fields.keys) {
          final keyStr = _keyToString(key).toLowerCase();
          final mockValue = _generateMockValue(keyStr, isBoundary: isBoundary);
          target.setAndValidateArrayField(i, key, mockValue);
        }
      }
      return true;
    }
    return false;
  }

  /// Imports a map of field values into the target [formId].
  bool importJsonState(String formId, Map<String, dynamic> values) {
    final entry = _entries[formId];
    if (entry == null) return false;

    final target = entry.target;
    if (target is NeatFormController) {
      for (final MapEntry(:key, :value) in values.entries) {
        final matchingKey = _findMatchingKey(target.state.fields.keys, key);
        if (matchingKey != null) {
          target.setAndValidateField(matchingKey, value);
        }
      }
      return true;
    } else if (target is NeatFormArrayController) {
      if (values['items'] is List) {
        final itemsList = values['items'] as List;
        target.clearItems();
        for (final item in itemsList) {
          if (item is Map) {
            final fieldMap = item['fields'] is Map ? item['fields'] as Map : item;
            target.addItem();
            final itemIndex = target.length - 1;
            final subForm = target.state.items[itemIndex].form;
            for (final MapEntry(:key, :value) in fieldMap.entries) {
              final matchingKey = _findMatchingKey(subForm.fields.keys, key.toString());
              if (matchingKey != null) {
                target.setAndValidateArrayField(itemIndex, matchingKey, value);
              }
            }
          }
        }
        return true;
      }
    }
    return false;
  }

  Object? _generateMockValue(String keyLower, {required bool isBoundary}) {
    if (isBoundary) {
      if (keyLower.contains('email')) return 'invalid-email-format';
      if (keyLower.contains('pass') || keyLower.contains('secret')) {
        return '123'; // Too short
      }
      if (keyLower.contains('phone') || keyLower.contains('tel')) {
        return 'abc-not-a-number';
      }
      if (keyLower.contains('name') || keyLower.contains('user')) {
        return ''; // Empty required field
      }
      if (keyLower.contains('age') || keyLower.contains('quantity') || keyLower.contains('count')) {
        return -10; // Negative boundary value
      }
      if (keyLower.contains('price') || keyLower.contains('amount')) {
        return 0;
      }
      if (keyLower.contains('url') || keyLower.contains('website') || keyLower.contains('link')) {
        return 'htt://broken-url';
      }
      if (keyLower.contains('agree') || keyLower.contains('terms') || keyLower.contains('consent')) {
        return false;
      }
      return '';
    }

    if (keyLower.contains('email')) return 'test.user@example.com';
    if (keyLower.contains('pass') || keyLower.contains('secret')) {
      return 'Secret@123456';
    }
    if (keyLower.contains('phone') || keyLower.contains('tel')) {
      return '0901234567';
    }
    if (keyLower.contains('name') || keyLower.contains('user')) {
      return 'Nguyen Van Test';
    }
    if (keyLower.contains('age') || keyLower.contains('quantity') || keyLower.contains('count')) {
      return 25;
    }
    if (keyLower.contains('price') || keyLower.contains('amount')) {
      return 150000;
    }
    if (keyLower.contains('date') || keyLower.contains('dob') || keyLower.contains('birth')) {
      return '15/08/1995';
    }
    if (keyLower.contains('url') || keyLower.contains('website') || keyLower.contains('link')) {
      return 'https://example.com';
    }
    if (keyLower.contains('address') || keyLower.contains('street') || keyLower.contains('city')) {
      return '123 Đường Nguyễn Huệ, Quận 1';
    }
    if (keyLower.contains('card') || keyLower.contains('cardnumber')) {
      return '4532 1234 5678 9010';
    }
    if (keyLower.contains('cvv') || keyLower.contains('cvc')) {
      return '123';
    }
    if (keyLower.contains('agree') || keyLower.contains('terms') || keyLower.contains('consent') || keyLower.contains('accept')) {
      return true;
    }
    return 'Sample $keyLower';
  }

  String _keyToString(Object? key) {
    if (key is Enum) return key.name;
    return key.toString();
  }

  Object? _findMatchingKey(Iterable<Object?> keys, String targetName) {
    for (final k in keys) {
      if (_keyToString(k) == targetName || k.toString() == targetName) {
        return k;
      }
    }
    return null;
  }

  void _cleanupDisposed() {
    _entries.removeWhere((_, entry) => entry.isDisposed);
  }
}
