import 'package:flutter/foundation.dart';
import 'package:neat_form/src/devtools/neat_form_devtools_bridge.dart';
import 'package:neat_form/src/devtools/neat_form_registry.dart';
import 'package:neat_form/src/field_state.dart';
import 'package:neat_form/src/validators.dart';

int _arrayIdCounter = 0;

String _generateUniqueId([String prefix = 'item']) {
  _arrayIdCounter++;
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  return '${prefix}_${timestamp}_$_arrayIdCounter';
}

/// A wrapper for a single sub-form item in a [NeatFormArrayState] with a stable unique [id].
@immutable
class NeatFormArrayItem<K> {
  /// Creates a sub-form item wrapper with a stable [id] and [form] state.
  NeatFormArrayItem({
    required this.form,
    String? id,
  }) : id = id ?? _generateUniqueId();

  /// A stable, collision-free unique identifier for this item in the list.
  ///
  /// Ideal for passing directly to Flutter's [ValueKey] or [Key] in ListView:
  /// ```dart
  /// Card(
  ///   key: ValueKey(item.id),
  ///   child: ...
  /// )
  /// ```
  final String id;

  /// The immutable [NeatFormState] of this specific item.
  final NeatFormState<K> form;

  /// Returns a copy of this array item with specified fields updated.
  NeatFormArrayItem<K> copyWith({
    String? id,
    NeatFormState<K>? form,
  }) {
    return NeatFormArrayItem<K>(
      id: id ?? this.id,
      form: form ?? this.form,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NeatFormArrayItem<K> &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          form == other.form;

  @override
  int get hashCode => Object.hash(id, form);

  @override
  String toString() => 'NeatFormArrayItem(id: $id, form: $form)';
}

/// An immutable container representing the state of a dynamic list of sub-forms.
@immutable
class NeatFormArrayState<K> {
  /// Creates an immutable array state with [items], optional array-level [error], and [status].
  const NeatFormArrayState({
    this.items = const [],
    this.error,
    this.showError = false,
    this.status = NeatSubmissionStatus.idle,
  });

  /// Factory constructor to initialize a [NeatFormArrayState] from a list of raw value maps.
  factory NeatFormArrayState.fromValuesList(
    List<Map<K, Object?>> valuesList, {
    Map<K, bool> optionalKeys = const {},
    NeatSubmissionStatus status = NeatSubmissionStatus.idle,
  }) {
    final items = valuesList
        .map(
          (values) => NeatFormArrayItem<K>(
            form: NeatFormState<K>.fromValues(
              values,
              optionalKeys: optionalKeys,
            ),
          ),
        )
        .toList();
    return NeatFormArrayState<K>(items: items, status: status);
  }

  /// The list of items in the array.
  final List<NeatFormArrayItem<K>> items;

  /// Array-level validation error (e.g. minItems, maxItems, duplicate values).
  final NeatValidationError? error;

  /// Whether the array-level error should be displayed in the UI.
  final bool showError;

  /// Current form array submission lifecycle status.
  final NeatSubmissionStatus status;

  /// Total number of items in the array.
  int get length => items.length;

  /// Whether the array contains no items.
  bool get isEmpty => items.isEmpty;

  /// Whether the array contains at least one item.
  bool get isNotEmpty => items.isNotEmpty;

  /// Returns `true` if array-level error is null AND all individual sub-forms are valid.
  bool get isValid => error == null && items.every((item) => item.form.isValid);

  /// Returns `true` if all sub-forms are clean and valid with no errors.
  bool get isCleanAndValid =>
      error == null && items.every((item) => item.form.isCleanAndValid);

  /// Returns `true` if any sub-form in the array has been modified from its initial value.
  bool get isDirty => items.any((item) => item.form.isDirty);

  /// Returns `true` if any field in any sub-form in the array has been touched/interacted with.
  bool get isTouched => items.any((item) => item.form.isTouched);

  /// True if any item in the array is currently undergoing async validation.
  bool get isValidating => items.any((item) => item.form.isValidating);

  /// Whether submission is currently in progress.
  bool get isSubmitting => status.isSubmitting;

  /// Whether the last submission attempt succeeded.
  bool get isSuccess => status.isSuccess;

  /// Whether the last submission attempt failed.
  bool get isFailure => status.isFailure;

  /// True if array error exists and is flagged to be shown in UI.
  bool get isErrorVisible => showError && error != null;

  /// Directly returns [NeatValidationError.message] if [isErrorVisible] is true, otherwise `null`.
  String? get errorMessage => isErrorVisible ? error?.message : null;

  /// Extracts all item sub-forms as a list of raw value maps: `List<Map<K, Object?>>`.
  List<Map<K, Object?>> get values => items.map((i) => i.form.values).toList();

  /// Index operator to access the [NeatFormState] of an item by index: `arrayState[index]`.
  NeatFormState<K> operator [](int index) => items[index].form;

  /// Retrieves an item by its unique [id], or `null` if not found.
  NeatFormArrayItem<K>? itemById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Returns the index of an item by its unique [id], or `-1` if not found.
  int indexOfId(String id) {
    return items.indexWhere((item) => item.id == id);
  }

  /// Returns a copy of this array state with specified fields updated.
  NeatFormArrayState<K> copyWith({
    List<NeatFormArrayItem<K>>? items,
    Object? error = _arraySentinel,
    bool? showError,
    NeatSubmissionStatus? status,
  }) {
    return NeatFormArrayState<K>(
      items: items ?? this.items,
      error: identical(error, _arraySentinel)
          ? this.error
          : error as NeatValidationError?,
      showError: showError ?? this.showError,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NeatFormArrayState<K> &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          showError == other.showError &&
          status == other.status &&
          listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(items),
        error,
        showError,
        status,
      );

  @override
  String toString() =>
      'NeatFormArrayState(items: ${items.length}, error: $error, status: $status)';
}

const Object _arraySentinel = Object();

/// A signature for an array-level validation function.
typedef NeatArrayValidator<K> = NeatValidationError? Function(
  NeatFormArrayState<K> state,
);

/// A collection of built-in array-level validators.
class NeatArrayValidators {
  NeatArrayValidators._();

  /// Error code for min items violation.
  static const String codeMinItems = 'array_min_items';

  /// Error code for max items violation.
  static const String codeMaxItems = 'array_max_items';

  /// Error code for length range violation.
  static const String codeLengthRange = 'array_length_range';

  /// Error code for duplicate value violation.
  static const String codeUniqueBy = 'array_unique_by';

  /// Validates that the array contains at least [min] items.
  static NeatArrayValidator<K> minItems<K>(
    int min, {
    String code = codeMinItems,
    String? message,
  }) {
    return (NeatFormArrayState<K> state) {
      if (state.length < min) {
        return NeatValidationError(
          code,
          params: {'min': min, 'count': state.length},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates that the array contains at most [max] items.
  static NeatArrayValidator<K> maxItems<K>(
    int max, {
    String code = codeMaxItems,
    String? message,
  }) {
    return (NeatFormArrayState<K> state) {
      if (state.length > max) {
        return NeatValidationError(
          code,
          params: {'max': max, 'count': state.length},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates that the array length is within [min] and [max] (inclusive).
  static NeatArrayValidator<K> lengthRange<K>(
    int min,
    int max, {
    String code = codeLengthRange,
    String? message,
  }) {
    return (NeatFormArrayState<K> state) {
      if (state.length < min || state.length > max) {
        return NeatValidationError(
          code,
          params: {'min': min, 'max': max, 'count': state.length},
          message: message,
        );
      }
      return null;
    };
  }

  /// Validates that all items in the array have unique values based on [selector].
  ///
  /// Supports trimming whitespace and case-insensitive comparison for emails/passports:
  /// ```dart
  /// NeatArrayValidators.uniqueBy<PassengerKey, String>(
  ///   (form) => form.valueOf<String>(PassengerKey.passportNumber),
  ///   caseSensitive: false,
  ///   message: 'Số hộ chiếu không được trùng nhau',
  /// )
  /// ```
  static NeatArrayValidator<K> uniqueBy<K, V>(
    V? Function(NeatFormState<K> form) selector, {
    String code = codeUniqueBy,
    String? message,
    bool ignoreEmpty = true,
    bool caseSensitive = true,
    bool trim = true,
  }) {
    return (NeatFormArrayState<K> state) {
      final seen = <Object>{};
      for (final item in state.items) {
        final rawVal = selector(item.form);
        if (rawVal == null) continue;

        Object val = rawVal;
        if (val is String) {
          if (trim) {
            val = val.trim();
          }
          if (ignoreEmpty && val.isEmpty) continue;
          if (!caseSensitive) {
            val = val.toLowerCase();
          }
        }

        if (seen.contains(val)) {
          return NeatValidationError(
            code,
            params: {'duplicateValue': rawVal},
            message: message,
          );
        }
        seen.add(val);
      }
      return null;
    };
  }

  /// Creates a custom array-level validator using a boolean predicate.
  static NeatArrayValidator<K> custom<K>(
    bool Function(NeatFormArrayState<K> state) predicate, {
    required String code,
    String? message,
    Map<String, Object?> params = const {},
  }) {
    return (NeatFormArrayState<K> state) {
      final isValid = predicate(state);
      if (!isValid) {
        return NeatValidationError(code, params: params, message: message);
      }
      return null;
    };
  }
}

/// Internal engine executing array-level mutations and validations.
class _NeatFormArrayEngine {
  static NeatFormArrayState<K> addItem<K>({
    required NeatFormArrayState<K> state,
    Map<K, Object?> initialValues = const {},
    Map<K, bool> optionalKeys = const {},
    Iterable<K>? templateKeys,
    String? id,
  }) {
    final values = Map<K, Object?>.from(initialValues);
    if (templateKeys != null) {
      for (final k in templateKeys) {
        values.putIfAbsent(k, () => null);
      }
    }
    final newItem = NeatFormArrayItem<K>(
      id: id,
      form: NeatFormState<K>.fromValues(
        values,
        optionalKeys: optionalKeys,
      ),
    );
    final newItems = List<NeatFormArrayItem<K>>.from(state.items)..add(newItem);
    return state.copyWith(items: newItems);
  }

  static NeatFormArrayState<K> insertItem<K>({
    required NeatFormArrayState<K> state,
    required int index,
    Map<K, Object?> initialValues = const {},
    Map<K, bool> optionalKeys = const {},
    Iterable<K>? templateKeys,
    String? id,
  }) {
    if (index < 0 || index > state.length) {
      throw RangeError.range(index, 0, state.length, 'index');
    }
    final values = Map<K, Object?>.from(initialValues);
    if (templateKeys != null) {
      for (final k in templateKeys) {
        values.putIfAbsent(k, () => null);
      }
    }
    final newItem = NeatFormArrayItem<K>(
      id: id,
      form: NeatFormState<K>.fromValues(
        values,
        optionalKeys: optionalKeys,
      ),
    );
    final newItems = List<NeatFormArrayItem<K>>.from(state.items)
      ..insert(index, newItem);
    return state.copyWith(items: newItems);
  }

  static NeatFormArrayState<K> removeItemAt<K>({
    required NeatFormArrayState<K> state,
    required int index,
  }) {
    if (index < 0 || index >= state.length) {
      throw RangeError.range(index, 0, state.length - 1, 'index');
    }
    final newItems = List<NeatFormArrayItem<K>>.from(state.items)
      ..removeAt(index);
    return state.copyWith(items: newItems);
  }

  static NeatFormArrayState<K> removeItemById<K>({
    required NeatFormArrayState<K> state,
    required String id,
  }) {
    final newItems = state.items.where((i) => i.id != id).toList();
    return state.copyWith(items: newItems);
  }

  static NeatFormArrayState<K> removeWhere<K>({
    required NeatFormArrayState<K> state,
    required bool Function(NeatFormArrayItem<K> item) test,
  }) {
    final newItems = state.items.where((i) => !test(i)).toList();
    return state.copyWith(items: newItems);
  }

  static NeatFormArrayState<K> clearItems<K>({
    required NeatFormArrayState<K> state,
  }) {
    return state.copyWith(items: const []);
  }

  static NeatFormArrayState<K> setItems<K>({
    required NeatFormArrayState<K> state,
    required List<Map<K, Object?>> valuesList,
    Map<K, bool> optionalKeys = const {},
    Iterable<K>? templateKeys,
  }) {
    final newItems = valuesList.map((valMap) {
      final values = Map<K, Object?>.from(valMap);
      if (templateKeys != null) {
        for (final k in templateKeys) {
          values.putIfAbsent(k, () => null);
        }
      }
      return NeatFormArrayItem<K>(
        form: NeatFormState<K>.fromValues(
          values,
          optionalKeys: optionalKeys,
        ),
      );
    }).toList();
    return state.copyWith(items: newItems);
  }

  static NeatFormArrayState<K> moveItem<K>({
    required NeatFormArrayState<K> state,
    required int fromIndex,
    required int toIndex,
  }) {
    if (fromIndex < 0 || fromIndex >= state.length) {
      throw RangeError.range(fromIndex, 0, state.length - 1, 'fromIndex');
    }
    var targetIndex = toIndex;
    if (targetIndex > fromIndex) {
      targetIndex -= 1;
    }
    if (targetIndex < 0 || targetIndex >= state.length) {
      throw RangeError.range(toIndex, 0, state.length, 'toIndex');
    }
    final newItems = List<NeatFormArrayItem<K>>.from(state.items);
    final item = newItems.removeAt(fromIndex);
    newItems.insert(targetIndex, item);
    return state.copyWith(items: newItems);
  }

  static NeatFormArrayState<K> setArrayField<T, K>({
    required NeatFormArrayState<K> state,
    required int itemIndex,
    required K key,
    required T value,
    required bool touch,
    required bool clearError,
  }) {
    if (itemIndex < 0 || itemIndex >= state.length) {
      throw RangeError.range(itemIndex, 0, state.length - 1, 'itemIndex');
    }
    final currentItem = state.items[itemIndex];
    final currentForm = currentItem.form;
    final currentField = currentForm.fields[key] ??
        NeatFieldState<Object?>(value: value, initialValue: value);

    final newField = currentField.copyWith(
      value: value,
      error: clearError ? null : currentField.error,
      showError: !clearError && currentField.showError,
      isTouched: touch || currentField.isTouched,
    );

    final newFields = Map<K, NeatFieldState<Object?>>.from(currentForm.fields);
    newFields[key] = newField;

    final updatedForm = currentForm.copyWith(fields: newFields);
    final updatedItem = currentItem.copyWith(form: updatedForm);

    final newItems = List<NeatFormArrayItem<K>>.from(state.items);
    newItems[itemIndex] = updatedItem;

    return state.copyWith(items: newItems);
  }

  static NeatFormArrayState<K> setAndValidateArrayField<T, K>({
    required NeatFormArrayState<K> state,
    required Map<K, NeatValidator<Object?>> itemValidators,
    required int itemIndex,
    required K key,
    required T value,
    required NeatValidator<T>? validator,
    required bool touch,
  }) {
    if (itemIndex < 0 || itemIndex >= state.length) {
      throw RangeError.range(itemIndex, 0, state.length - 1, 'itemIndex');
    }
    final currentItem = state.items[itemIndex];
    final currentForm = currentItem.form;
    final currentField = currentForm.fields[key] ??
        NeatFieldState<Object?>(value: value, initialValue: value);

    final validatorToRun =
        validator ?? (itemValidators[key] as NeatValidator<T>?);
    final error = validatorToRun?.call(value);

    final newField = currentField.copyWith(
      value: value,
      error: error,
      showError: true,
      isTouched: touch || currentField.isTouched,
      isValidated: true,
    );

    final newFields = Map<K, NeatFieldState<Object?>>.from(currentForm.fields);
    newFields[key] = newField;

    final updatedForm = currentForm.copyWith(fields: newFields);
    final updatedItem = currentItem.copyWith(form: updatedForm);

    final newItems = List<NeatFormArrayItem<K>>.from(state.items);
    newItems[itemIndex] = updatedItem;

    return state.copyWith(items: newItems);
  }

  static (NeatFormArrayState<K>, bool) validateArray<K>({
    required NeatFormArrayState<K> state,
    required Map<K, NeatValidator<Object?>> itemValidators,
    required List<NeatArrayValidator<K>> arrayValidators,
  }) {
    var allItemsValid = true;
    final validatedItems = <NeatFormArrayItem<K>>[];

    // 1. Validate each sub-form across fields union with itemValidators
    for (final item in state.items) {
      final newFields = Map<K, NeatFieldState<Object?>>.from(item.form.fields);
      var itemValid = true;

      final allKeys = {...item.form.fields.keys, ...itemValidators.keys};
      for (final key in allKeys) {
        final field = item.form.fields[key] ??
            const NeatFieldState<Object?>(value: null, initialValue: null);
        final validator = itemValidators[key];
        final error = validator?.call(field.value);

        if (error != null) {
          itemValid = false;
        }

        newFields[key] = field.copyWith(
          error: error,
          showError: true,
          isValidated: true,
        );
      }

      if (!itemValid) {
        allItemsValid = false;
      }
      validatedItems.add(
        item.copyWith(form: item.form.copyWith(fields: newFields)),
      );
    }

    // 2. Validate array-level validators
    final tempState = state.copyWith(items: validatedItems);
    NeatValidationError? arrayError;

    for (final arrayValidator in arrayValidators) {
      final err = arrayValidator(tempState);
      if (err != null) {
        arrayError = err;
        break;
      }
    }

    final finalState = tempState.copyWith(
      error: arrayError,
      showError: true,
    );

    final overallValid = allItemsValid && arrayError == null;
    return (finalState, overallValid);
  }

  static NeatFormArrayState<K> resetArray<K>({
    required NeatFormArrayState<K> state,
  }) {
    final resetItems = state.items.map((item) {
      final resetFields = item.form.fields.map((key, field) {
        return MapEntry(
          key,
          field.copyWith(
            value: field.initialValue,
            error: null,
            showError: false,
            isTouched: false,
            isValidating: false,
            isValidated: false,
          ),
        );
      });
      return item.copyWith(
        form: item.form.copyWith(
          fields: resetFields,
          status: NeatSubmissionStatus.idle,
        ),
      );
    }).toList();

    return state.copyWith(
      items: resetItems,
      error: null,
      showError: false,
      status: NeatSubmissionStatus.idle,
    );
  }
}

/// A controller managing a dynamic list of sub-forms with Flutter [ChangeNotifier] integration.
class NeatFormArrayController<K> extends ChangeNotifier {
  /// Creates a form array controller with optional initial items and validators.
  NeatFormArrayController({
    List<Map<K, Object?>> initialItems = const [],
    Map<K, bool> optionalKeys = const {},
    this.itemValidators = const {},
    this.arrayValidators = const [],
    String? debugName,
    bool enableDevTools = true,
  })  : _state = NeatFormArrayState<K>.fromValuesList(
          initialItems,
          optionalKeys: optionalKeys,
        ),
        _debugName = debugName {
    if (enableDevTools && !kReleaseMode) {
      NeatFormDevToolsBridge.init();
      _devToolsFormId = NeatFormDevToolsRegistry.instance.registerArrayController(
        this,
        debugName: debugName,
      );
      NeatFormDevToolsBridge.postEvent('form_registered', {
        'formId': _devToolsFormId,
        'name': _debugName ?? 'FormArray ($K)',
        'type': 'array',
      });
    }
  }

  NeatFormArrayState<K> _state;
  final String? _debugName;
  String? _devToolsFormId;
  bool _isDisposed = false;

  /// Unique ID assigned by DevTools registry, if registered.
  String? get devToolsFormId => _devToolsFormId;

  /// Optional debug name for this form array.
  String? get debugName => _debugName;

  /// The map of validators applied to each item's fields.
  final Map<K, NeatValidator<Object?>> itemValidators;

  /// The list of array-level validators (e.g. minItems, maxItems, uniqueBy).
  final List<NeatArrayValidator<K>> arrayValidators;

  /// Current immutable state of the form array.
  NeatFormArrayState<K> get state => _state;

  /// Current items list in the array.
  List<NeatFormArrayItem<K>> get items => _state.items;

  /// Total number of items in the array.
  int get length => _state.length;

  /// Whether the array contains no items.
  bool get isEmpty => _state.isEmpty;

  /// Whether the array contains at least one item.
  bool get isNotEmpty => _state.isNotEmpty;

  /// Current submission lifecycle status.
  NeatSubmissionStatus get submissionStatus => _state.status;

  /// True if the controller has been disposed.
  bool get isDisposed => _isDisposed;

  /// True if all items and array validators are valid.
  bool get isValid => _state.isValid;

  /// True if any field in any item has changed.
  bool get isDirty => _state.isDirty;

  /// Extracts all item values as `List<Map<K, Object?>>`.
  List<Map<K, Object?>> get values => _state.values;

  /// Index operator to access item form: `controller[index]`.
  NeatFormState<K> operator [](int index) => _state[index];

  void _setState(NeatFormArrayState<K> newState) {
    if (_isDisposed || _state == newState) return;
    _state = newState;
    if (_devToolsFormId != null) {
      NeatFormDevToolsBridge.postEvent('form_array_updated', {
        'formId': _devToolsFormId,
        'length': _state.length,
        'isValid': _state.isValid,
        'isTouched': _state.isTouched,
        'status': _state.status.name,
      });
    }
    notifyListeners();
  }

  /// Adds a new sub-form item to the end of the array.
  void addItem([
    Map<K, Object?> initialValues = const {},
    Map<K, bool> optionalKeys = const {},
    String? id,
  ]) {
    _setState(
      _NeatFormArrayEngine.addItem<K>(
        state: _state,
        initialValues: initialValues,
        optionalKeys: optionalKeys,
        templateKeys: itemValidators.keys,
        id: id,
      ),
    );
  }

  /// Inserts a new sub-form item at [index].
  void insertItem(
    int index, [
    Map<K, Object?> initialValues = const {},
    Map<K, bool> optionalKeys = const {},
    String? id,
  ]) {
    _setState(
      _NeatFormArrayEngine.insertItem<K>(
        state: _state,
        index: index,
        initialValues: initialValues,
        optionalKeys: optionalKeys,
        templateKeys: itemValidators.keys,
        id: id,
      ),
    );
  }

  /// Removes an item at [index].
  void removeItemAt(int index) {
    _setState(
      _NeatFormArrayEngine.removeItemAt<K>(
        state: _state,
        index: index,
      ),
    );
  }

  /// Removes an item by its unique [id].
  void removeItemById(String id) {
    _setState(
      _NeatFormArrayEngine.removeItemById<K>(
        state: _state,
        id: id,
      ),
    );
  }

  /// Removes all items matching the provided [test] predicate.
  void removeWhere(bool Function(NeatFormArrayItem<K> item) test) {
    _setState(_NeatFormArrayEngine.removeWhere<K>(state: _state, test: test));
  }

  /// Clears all items in the array.
  void clearItems() {
    _setState(_NeatFormArrayEngine.clearItems<K>(state: _state));
  }

  /// Replaces all items in the array with a new [valuesList].
  void setItems(
    List<Map<K, Object?>> valuesList, {
    Map<K, bool> optionalKeys = const {},
  }) {
    _setState(
      _NeatFormArrayEngine.setItems<K>(
        state: _state,
        valuesList: valuesList,
        optionalKeys: optionalKeys,
        templateKeys: itemValidators.keys,
      ),
    );
  }

  /// Moves an item from [fromIndex] to [toIndex] (perfect for `ReorderableListView`).
  void moveItem(int fromIndex, int toIndex) {
    _setState(
      _NeatFormArrayEngine.moveItem<K>(
        state: _state,
        fromIndex: fromIndex,
        toIndex: toIndex,
      ),
    );
  }

  /// Convenience handler for Flutter's `ReorderableListView` `onReorder(oldIndex, newIndex)`.
  void reorderItem(int oldIndex, int newIndex) {
    moveItem(oldIndex, newIndex);
  }

  /// Updates a field in the sub-form at [itemIndex].
  void setArrayField<T>(
    int itemIndex,
    K key,
    T value, {
    bool touch = true,
    bool clearError = true,
  }) {
    _setState(
      _NeatFormArrayEngine.setArrayField<T, K>(
        state: _state,
        itemIndex: itemIndex,
        key: key,
        value: value,
        touch: touch,
        clearError: clearError,
      ),
    );
  }

  /// Sets and validates a field in the sub-form at [itemIndex] immediately.
  void setAndValidateArrayField<T>(
    int itemIndex,
    K key,
    T value, {
    NeatValidator<T>? validator,
    bool touch = true,
  }) {
    _setState(
      _NeatFormArrayEngine.setAndValidateArrayField<T, K>(
        state: _state,
        itemValidators: itemValidators,
        itemIndex: itemIndex,
        key: key,
        value: value,
        validator: validator,
        touch: touch,
      ),
    );
  }

  final Map<String, int> _asyncTokens = {};

  /// Asynchronously validates a field in the sub-form at [itemIndex] with auto race-condition cancellation.
  Future<void> validateArrayFieldAsync<T>(
    int itemIndex,
    K key,
    Future<NeatValidationError?> Function(T? value) asyncValidator, {
    bool touch = true,
  }) async {
    if (itemIndex < 0 || itemIndex >= length) return;
    final item = items[itemIndex];
    final currentField = item.form.fields[key];
    final value = currentField?.value as T?;

    final tokenKey = '${item.id}_$key';
    final token = (_asyncTokens[tokenKey] ?? 0) + 1;
    _asyncTokens[tokenKey] = token;

    // Set validating status
    final field = (currentField ?? NeatFieldState<Object?>(value: value, initialValue: value)).copyWith(
      isValidating: true,
      isTouched: touch || (currentField?.isTouched ?? false),
    );
    final newFields = Map<K, NeatFieldState<Object?>>.from(item.form.fields);
    newFields[key] = field;
    final newItems = List<NeatFormArrayItem<K>>.from(items);
    newItems[itemIndex] = item.copyWith(form: item.form.copyWith(fields: newFields));
    _setState(state.copyWith(items: newItems));

    try {
      final error = await asyncValidator(value);
      if (_isDisposed || _asyncTokens[tokenKey] != token) return;
      if (itemIndex >= length || items[itemIndex].id != item.id) return;

      final resolvedField = items[itemIndex].form.fields[key]?.copyWith(
            error: error,
            showError: error != null,
            isValidating: false,
            isValidated: true,
          );
      if (resolvedField != null) {
        final updatedFields = Map<K, NeatFieldState<Object?>>.from(items[itemIndex].form.fields);
        updatedFields[key] = resolvedField;
        final updatedItems = List<NeatFormArrayItem<K>>.from(items);
        updatedItems[itemIndex] = items[itemIndex].copyWith(form: items[itemIndex].form.copyWith(fields: updatedFields));
        _setState(state.copyWith(items: updatedItems));
      }
    } on Object catch (_) {
      if (_isDisposed || _asyncTokens[tokenKey] != token) return;
      if (itemIndex < length && items[itemIndex].id == item.id) {
        final fallbackField = items[itemIndex].form.fields[key]?.copyWith(isValidating: false);
        if (fallbackField != null) {
          final updatedFields = Map<K, NeatFieldState<Object?>>.from(items[itemIndex].form.fields);
          updatedFields[key] = fallbackField;
          final updatedItems = List<NeatFormArrayItem<K>>.from(items);
          updatedItems[itemIndex] = items[itemIndex].copyWith(form: items[itemIndex].form.copyWith(fields: updatedFields));
          _setState(state.copyWith(items: updatedItems));
        }
      }
    }
  }

  /// Validates all sub-forms and array-level validators.
  bool validateArray() {
    final (newState, isValid) = _NeatFormArrayEngine.validateArray<K>(
      state: _state,
      itemValidators: itemValidators,
      arrayValidators: arrayValidators,
    );
    _setState(newState);
    return isValid;
  }

  /// Submits the array form if valid, executing [onSubmit].
  Future<bool> submitForm({
    required Future<void> Function(List<Map<K, Object?>> values) onSubmit,
    void Function(NeatValidationError? arrayError, List<Map<K, NeatValidationError>> itemErrors)? onError,
  }) async {
    final isValid = validateArray();
    if (!isValid) {
      _setState(_state.copyWith(status: NeatSubmissionStatus.failure));
      if (onError != null) {
        final itemErrors = _state.items.map((item) {
          final errs = <K, NeatValidationError>{};
          for (final entry in item.form.fields.entries) {
            if (entry.value.error != null) {
              errs[entry.key] = entry.value.error!;
            }
          }
          return errs;
        }).toList();
        onError(_state.error, itemErrors);
      }
      return false;
    }

    _setState(_state.copyWith(status: NeatSubmissionStatus.submitting));

    try {
      await onSubmit(values);
      _setState(_state.copyWith(status: NeatSubmissionStatus.success));
      return true;
    } on Exception {
      _setState(_state.copyWith(status: NeatSubmissionStatus.failure));
      rethrow;
    } catch (_) {
      _setState(_state.copyWith(status: NeatSubmissionStatus.failure));
      rethrow;
    }
  }

  /// Resets all items to their initial values and clears all errors.
  void resetArray() {
    _setState(_NeatFormArrayEngine.resetArray<K>(state: _state));
  }

  /// Clears errors across all items and array-level error without changing values.
  void clearErrors() {
    final cleanItems = _state.items.map((item) {
      final cleanFields = item.form.fields.map((key, field) {
        return MapEntry(
          key,
          field.copyWith(error: null, showError: false),
        );
      });
      return item.copyWith(
        form: item.form.copyWith(fields: cleanFields),
      );
    }).toList();

    _setState(
      _state.copyWith(
        items: cleanItems,
        error: null,
        showError: false,
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_devToolsFormId != null) {
      NeatFormDevToolsRegistry.instance.unregister(_devToolsFormId);
      NeatFormDevToolsBridge.postEvent('form_unregistered', {
        'formId': _devToolsFormId,
      });
      _devToolsFormId = null;
    }
    super.dispose();
  }
}

/// Standalone mixin for **Riverpod** (`Notifier<NeatFormArrayState<K>>`) managing dynamic form arrays.
mixin NeatFormArrayNotifierMixin<K> {
  /// Current state of the form array.
  NeatFormArrayState<K> get state;

  /// State setter for the form array.
  set state(NeatFormArrayState<K> value);

  /// Map of validators for each item's fields.
  @protected
  Map<K, NeatValidator<Object?>> get itemValidators => const {};

  /// List of array-level validators.
  @protected
  List<NeatArrayValidator<K>> get arrayValidators => const [];

  /// Current submission status.
  NeatSubmissionStatus get submissionStatus => state.status;

  /// Total number of items in the array.
  int get length => state.length;

  /// Whether the array contains no items.
  bool get isEmpty => state.isEmpty;

  /// Whether the array contains at least one item.
  bool get isNotEmpty => state.isNotEmpty;

  /// True if all items and array validators are valid.
  bool get isValid => state.isValid;

  /// True if any field in any item has changed.
  bool get isDirty => state.isDirty;

  /// Extracts all item values as `List<Map<K, Object?>>`.
  List<Map<K, Object?>> get values => state.values;

  /// Index operator to access item form: `notifier[index]`.
  NeatFormState<K> operator [](int index) => state[index];

  /// Adds an item to the array.
  void addItem([
    Map<K, Object?> initialValues = const {},
    Map<K, bool> optionalKeys = const {},
    String? id,
  ]) {
    state = _NeatFormArrayEngine.addItem<K>(
      state: state,
      initialValues: initialValues,
      optionalKeys: optionalKeys,
      templateKeys: itemValidators.keys,
      id: id,
    );
  }

  /// Inserts an item at [index].
  void insertItem(
    int index, [
    Map<K, Object?> initialValues = const {},
    Map<K, bool> optionalKeys = const {},
    String? id,
  ]) {
    state = _NeatFormArrayEngine.insertItem<K>(
      state: state,
      index: index,
      initialValues: initialValues,
      optionalKeys: optionalKeys,
      templateKeys: itemValidators.keys,
      id: id,
    );
  }

  /// Removes an item at [index].
  void removeItemAt(int index) {
    state = _NeatFormArrayEngine.removeItemAt<K>(
      state: state,
      index: index,
    );
  }

  /// Removes an item by [id].
  void removeItemById(String id) {
    state = _NeatFormArrayEngine.removeItemById<K>(
      state: state,
      id: id,
    );
  }

  /// Removes all items matching the provided [test] predicate.
  void removeWhere(bool Function(NeatFormArrayItem<K> item) test) {
    state = _NeatFormArrayEngine.removeWhere<K>(state: state, test: test);
  }

  /// Clears all items in the array.
  void clearItems() {
    state = _NeatFormArrayEngine.clearItems<K>(state: state);
  }

  /// Replaces all items in the array with a new [valuesList].
  void setItems(
    List<Map<K, Object?>> valuesList, {
    Map<K, bool> optionalKeys = const {},
  }) {
    state = _NeatFormArrayEngine.setItems<K>(
      state: state,
      valuesList: valuesList,
      optionalKeys: optionalKeys,
      templateKeys: itemValidators.keys,
    );
  }

  /// Moves an item from [fromIndex] to [toIndex].
  void moveItem(int fromIndex, int toIndex) {
    state = _NeatFormArrayEngine.moveItem<K>(
      state: state,
      fromIndex: fromIndex,
      toIndex: toIndex,
    );
  }

  /// Updates a field in the sub-form at [itemIndex].
  void setArrayField<T>(
    int itemIndex,
    K key,
    T value, {
    bool touch = true,
    bool clearError = true,
  }) {
    state = _NeatFormArrayEngine.setArrayField<T, K>(
      state: state,
      itemIndex: itemIndex,
      key: key,
      value: value,
      touch: touch,
      clearError: clearError,
    );
  }

  /// Sets and validates a field in the sub-form at [itemIndex] immediately.
  void setAndValidateArrayField<T>(
    int itemIndex,
    K key,
    T value, {
    NeatValidator<T>? validator,
    bool touch = true,
  }) {
    state = _NeatFormArrayEngine.setAndValidateArrayField<T, K>(
      state: state,
      itemValidators: itemValidators,
      itemIndex: itemIndex,
      key: key,
      value: value,
      validator: validator,
      touch: touch,
    );
  }

  /// Validates all sub-forms and array-level validators.
  bool validateArray() {
    final (newState, isValid) = _NeatFormArrayEngine.validateArray<K>(
      state: state,
      itemValidators: itemValidators,
      arrayValidators: arrayValidators,
    );
    state = newState;
    return isValid;
  }

  /// Submits the form array if valid.
  Future<bool> submitForm({
    required Future<void> Function(List<Map<K, Object?>> values) onSubmit,
    void Function(NeatValidationError? arrayError, List<Map<K, NeatValidationError>> itemErrors)? onError,
  }) async {
    final isValid = validateArray();
    if (!isValid) {
      state = state.copyWith(status: NeatSubmissionStatus.failure);
      if (onError != null) {
        final itemErrors = state.items.map((item) {
          final errs = <K, NeatValidationError>{};
          for (final entry in item.form.fields.entries) {
            if (entry.value.error != null) {
              errs[entry.key] = entry.value.error!;
            }
          }
          return errs;
        }).toList();
        onError(state.error, itemErrors);
      }
      return false;
    }

    state = state.copyWith(status: NeatSubmissionStatus.submitting);

    try {
      await onSubmit(state.values);
      state = state.copyWith(status: NeatSubmissionStatus.success);
      return true;
    } on Exception {
      state = state.copyWith(status: NeatSubmissionStatus.failure);
      rethrow;
    } catch (_) {
      state = state.copyWith(status: NeatSubmissionStatus.failure);
      rethrow;
    }
  }

  /// Resets the array to its initial state.
  void resetArray() {
    state = _NeatFormArrayEngine.resetArray<K>(state: state);
  }
}

/// Standalone mixin for **BLoC / Cubit** (`Cubit<NeatFormArrayState<K>>`) managing dynamic form arrays.
mixin NeatFormArrayCubitMixin<K> {
  /// Current state of the Cubit.
  NeatFormArrayState<K> get state;

  /// Emit function provided by Cubit.
  void emit(NeatFormArrayState<K> state);

  /// Map of validators for each item's fields.
  @protected
  Map<K, NeatValidator<Object?>> get itemValidators => const {};

  /// List of array-level validators.
  @protected
  List<NeatArrayValidator<K>> get arrayValidators => const [];

  /// Current submission status.
  NeatSubmissionStatus get submissionStatus => state.status;

  /// Total number of items in the array.
  int get length => state.length;

  /// Whether the array contains no items.
  bool get isEmpty => state.isEmpty;

  /// Whether the array contains at least one item.
  bool get isNotEmpty => state.isNotEmpty;

  /// True if all items and array validators are valid.
  bool get isValid => state.isValid;

  /// True if any field in any item has changed.
  bool get isDirty => state.isDirty;

  /// Extracts all item values as `List<Map<K, Object?>>`.
  List<Map<K, Object?>> get values => state.values;

  /// Index operator to access item form: `cubit[index]`.
  NeatFormState<K> operator [](int index) => state[index];

  /// Adds an item to the array.
  void addItem([
    Map<K, Object?> initialValues = const {},
    Map<K, bool> optionalKeys = const {},
    String? id,
  ]) {
    emit(
      _NeatFormArrayEngine.addItem<K>(
        state: state,
        initialValues: initialValues,
        optionalKeys: optionalKeys,
        templateKeys: itemValidators.keys,
        id: id,
      ),
    );
  }

  /// Inserts an item at [index].
  void insertItem(
    int index, [
    Map<K, Object?> initialValues = const {},
    Map<K, bool> optionalKeys = const {},
    String? id,
  ]) {
    emit(
      _NeatFormArrayEngine.insertItem<K>(
        state: state,
        index: index,
        initialValues: initialValues,
        optionalKeys: optionalKeys,
        templateKeys: itemValidators.keys,
        id: id,
      ),
    );
  }

  /// Removes an item at [index].
  void removeItemAt(int index) {
    emit(
      _NeatFormArrayEngine.removeItemAt<K>(
        state: state,
        index: index,
      ),
    );
  }

  /// Removes an item by [id].
  void removeItemById(String id) {
    emit(
      _NeatFormArrayEngine.removeItemById<K>(
        state: state,
        id: id,
      ),
    );
  }

  /// Removes all items matching the provided [test] predicate.
  void removeWhere(bool Function(NeatFormArrayItem<K> item) test) {
    emit(_NeatFormArrayEngine.removeWhere<K>(state: state, test: test));
  }

  /// Clears all items in the array.
  void clearItems() {
    emit(_NeatFormArrayEngine.clearItems<K>(state: state));
  }

  /// Replaces all items in the array with a new [valuesList].
  void setItems(
    List<Map<K, Object?>> valuesList, {
    Map<K, bool> optionalKeys = const {},
  }) {
    emit(
      _NeatFormArrayEngine.setItems<K>(
        state: state,
        valuesList: valuesList,
        optionalKeys: optionalKeys,
        templateKeys: itemValidators.keys,
      ),
    );
  }

  /// Moves an item from [fromIndex] to [toIndex].
  void moveItem(int fromIndex, int toIndex) {
    emit(
      _NeatFormArrayEngine.moveItem<K>(
        state: state,
        fromIndex: fromIndex,
        toIndex: toIndex,
      ),
    );
  }

  /// Updates a field in the sub-form at [itemIndex].
  void setArrayField<T>(
    int itemIndex,
    K key,
    T value, {
    bool touch = true,
    bool clearError = true,
  }) {
    emit(
      _NeatFormArrayEngine.setArrayField<T, K>(
        state: state,
        itemIndex: itemIndex,
        key: key,
        value: value,
        touch: touch,
        clearError: clearError,
      ),
    );
  }

  /// Sets and validates a field in the sub-form at [itemIndex] immediately.
  void setAndValidateArrayField<T>(
    int itemIndex,
    K key,
    T value, {
    NeatValidator<T>? validator,
    bool touch = true,
  }) {
    emit(
      _NeatFormArrayEngine.setAndValidateArrayField<T, K>(
        state: state,
        itemValidators: itemValidators,
        itemIndex: itemIndex,
        key: key,
        value: value,
        validator: validator,
        touch: touch,
      ),
    );
  }

  /// Validates all sub-forms and array-level validators.
  bool validateArray() {
    final (newState, isValid) = _NeatFormArrayEngine.validateArray<K>(
      state: state,
      itemValidators: itemValidators,
      arrayValidators: arrayValidators,
    );
    emit(newState);
    return isValid;
  }

  /// Submits the form array if valid.
  Future<bool> submitForm({
    required Future<void> Function(List<Map<K, Object?>> values) onSubmit,
    void Function(NeatValidationError? arrayError, List<Map<K, NeatValidationError>> itemErrors)? onError,
  }) async {
    final isValid = validateArray();
    if (!isValid) {
      emit(state.copyWith(status: NeatSubmissionStatus.failure));
      if (onError != null) {
        final itemErrors = state.items.map((item) {
          final errs = <K, NeatValidationError>{};
          for (final entry in item.form.fields.entries) {
            if (entry.value.error != null) {
              errs[entry.key] = entry.value.error!;
            }
          }
          return errs;
        }).toList();
        onError(state.error, itemErrors);
      }
      return false;
    }

    emit(state.copyWith(status: NeatSubmissionStatus.submitting));

    try {
      await onSubmit(state.values);
      emit(state.copyWith(status: NeatSubmissionStatus.success));
      return true;
    } on Exception {
      emit(state.copyWith(status: NeatSubmissionStatus.failure));
      rethrow;
    } catch (_) {
      emit(state.copyWith(status: NeatSubmissionStatus.failure));
      rethrow;
    }
  }

  /// Resets the array to its initial state.
  void resetArray() {
    emit(_NeatFormArrayEngine.resetArray<K>(state: state));
  }
}

/// Mixin for **Riverpod** Notifiers managing a nested form array inside a Screen State [S].
mixin NeatNestedFormArrayNotifierMixin<S, K> {
  /// The current Screen State [S] (e.g. Riverpod `state`).
  S get state;

  /// Setter to update the Screen State [S] (e.g. Riverpod `state = ...`).
  set state(S value);

  /// Extracts the nested [NeatFormArrayState<K>] from the parent state [S].
  NeatFormArrayState<K> getArrayForm(S state);

  /// Returns a copy of [state] with the nested [arrayForm] updated.
  S updateArrayForm(S state, NeatFormArrayState<K> arrayForm);

  /// Current array form state.
  NeatFormArrayState<K> get arrayState => getArrayForm(state);

  /// Map of validators for each item's fields.
  @protected
  Map<K, NeatValidator<Object?>> get itemValidators => const {};

  /// List of array-level validators.
  @protected
  List<NeatArrayValidator<K>> get arrayValidators => const [];

  /// Current submission status.
  NeatSubmissionStatus get submissionStatus => arrayState.status;

  /// Total number of items in the array.
  int get length => arrayState.length;

  /// Whether the array contains no items.
  bool get isEmpty => arrayState.isEmpty;

  /// Whether the array contains at least one item.
  bool get isNotEmpty => arrayState.isNotEmpty;

  /// True if all items and array validators are valid.
  bool get isValid => arrayState.isValid;

  /// True if any field in any item has changed.
  bool get isDirty => arrayState.isDirty;

  /// Extracts all item values as `List<Map<K, Object?>>`.
  List<Map<K, Object?>> get values => arrayState.values;

  /// Index operator to access item form: `notifier[index]`.
  NeatFormState<K> operator [](int index) => arrayState[index];

  void _setArrayState(NeatFormArrayState<K> newArrayState) {
    state = updateArrayForm(state, newArrayState);
  }

  /// Adds an item to the array.
  void addItem([
    Map<K, Object?> initialValues = const {},
    Map<K, bool> optionalKeys = const {},
    String? id,
  ]) {
    _setArrayState(
      _NeatFormArrayEngine.addItem<K>(
        state: arrayState,
        initialValues: initialValues,
        optionalKeys: optionalKeys,
        templateKeys: itemValidators.keys,
        id: id,
      ),
    );
  }

  /// Inserts an item at [index].
  void insertItem(
    int index, [
    Map<K, Object?> initialValues = const {},
    Map<K, bool> optionalKeys = const {},
    String? id,
  ]) {
    _setArrayState(
      _NeatFormArrayEngine.insertItem<K>(
        state: arrayState,
        index: index,
        initialValues: initialValues,
        optionalKeys: optionalKeys,
        templateKeys: itemValidators.keys,
        id: id,
      ),
    );
  }

  /// Removes an item at [index].
  void removeItemAt(int index) {
    _setArrayState(
      _NeatFormArrayEngine.removeItemAt<K>(
        state: arrayState,
        index: index,
      ),
    );
  }

  /// Removes an item by [id].
  void removeItemById(String id) {
    _setArrayState(
      _NeatFormArrayEngine.removeItemById<K>(
        state: arrayState,
        id: id,
      ),
    );
  }

  /// Removes all items matching the provided [test] predicate.
  void removeWhere(bool Function(NeatFormArrayItem<K> item) test) {
    _setArrayState(_NeatFormArrayEngine.removeWhere<K>(state: arrayState, test: test));
  }

  /// Clears all items in the array.
  void clearItems() {
    _setArrayState(_NeatFormArrayEngine.clearItems<K>(state: arrayState));
  }

  /// Replaces all items in the array with a new [valuesList].
  void setItems(
    List<Map<K, Object?>> valuesList, {
    Map<K, bool> optionalKeys = const {},
  }) {
    _setArrayState(
      _NeatFormArrayEngine.setItems<K>(
        state: arrayState,
        valuesList: valuesList,
        optionalKeys: optionalKeys,
        templateKeys: itemValidators.keys,
      ),
    );
  }

  /// Moves an item from [fromIndex] to [toIndex].
  void moveItem(int fromIndex, int toIndex) {
    _setArrayState(
      _NeatFormArrayEngine.moveItem<K>(
        state: arrayState,
        fromIndex: fromIndex,
        toIndex: toIndex,
      ),
    );
  }

  /// Updates a field in the sub-form at [itemIndex].
  void setArrayField<T>(
    int itemIndex,
    K key,
    T value, {
    bool touch = true,
    bool clearError = true,
  }) {
    _setArrayState(
      _NeatFormArrayEngine.setArrayField<T, K>(
        state: arrayState,
        itemIndex: itemIndex,
        key: key,
        value: value,
        touch: touch,
        clearError: clearError,
      ),
    );
  }

  /// Sets and validates a field in the sub-form at [itemIndex] immediately.
  void setAndValidateArrayField<T>(
    int itemIndex,
    K key,
    T value, {
    NeatValidator<T>? validator,
    bool touch = true,
  }) {
    _setArrayState(
      _NeatFormArrayEngine.setAndValidateArrayField<T, K>(
        state: arrayState,
        itemValidators: itemValidators,
        itemIndex: itemIndex,
        key: key,
        value: value,
        validator: validator,
        touch: touch,
      ),
    );
  }

  /// Validates all sub-forms and array-level validators.
  bool validateArray() {
    final (newState, isValid) = _NeatFormArrayEngine.validateArray<K>(
      state: arrayState,
      itemValidators: itemValidators,
      arrayValidators: arrayValidators,
    );
    _setArrayState(newState);
    return isValid;
  }

  /// Submits the form array if valid.
  Future<bool> submitForm({
    required Future<void> Function(List<Map<K, Object?>> values) onSubmit,
    void Function(NeatValidationError? arrayError, List<Map<K, NeatValidationError>> itemErrors)? onError,
  }) async {
    final isValid = validateArray();
    if (!isValid) {
      _setArrayState(arrayState.copyWith(status: NeatSubmissionStatus.failure));
      if (onError != null) {
        final itemErrors = arrayState.items.map((item) {
          final errs = <K, NeatValidationError>{};
          for (final entry in item.form.fields.entries) {
            if (entry.value.error != null) {
              errs[entry.key] = entry.value.error!;
            }
          }
          return errs;
        }).toList();
        onError(arrayState.error, itemErrors);
      }
      return false;
    }

    _setArrayState(arrayState.copyWith(status: NeatSubmissionStatus.submitting));

    try {
      await onSubmit(values);
      _setArrayState(arrayState.copyWith(status: NeatSubmissionStatus.success));
      return true;
    } on Exception {
      _setArrayState(arrayState.copyWith(status: NeatSubmissionStatus.failure));
      rethrow;
    } catch (_) {
      _setArrayState(arrayState.copyWith(status: NeatSubmissionStatus.failure));
      rethrow;
    }
  }

  /// Resets the array to its initial state.
  void resetArray() {
    _setArrayState(_NeatFormArrayEngine.resetArray<K>(state: arrayState));
  }
}

/// Mixin for **BLoC / Cubit** managing a nested form array inside a Screen State [S].
mixin NeatNestedFormArrayCubitMixin<S, K> {
  /// Current state of the Cubit.
  S get state;

  /// Emit function provided by Cubit.
  void emit(S state);

  /// Extracts the nested [NeatFormArrayState<K>] from the parent state [S].
  NeatFormArrayState<K> getArrayForm(S state);

  /// Returns a copy of [state] with the nested [arrayForm] updated.
  S updateArrayForm(S state, NeatFormArrayState<K> arrayForm);

  /// Current array form state.
  NeatFormArrayState<K> get arrayState => getArrayForm(state);

  /// Map of validators for each item's fields.
  @protected
  Map<K, NeatValidator<Object?>> get itemValidators => const {};

  /// List of array-level validators.
  @protected
  List<NeatArrayValidator<K>> get arrayValidators => const [];

  /// Current submission status.
  NeatSubmissionStatus get submissionStatus => arrayState.status;

  /// Total number of items in the array.
  int get length => arrayState.length;

  /// Whether the array contains no items.
  bool get isEmpty => arrayState.isEmpty;

  /// Whether the array contains at least one item.
  bool get isNotEmpty => arrayState.isNotEmpty;

  /// True if all items and array validators are valid.
  bool get isValid => arrayState.isValid;

  /// True if any field in any item has changed.
  bool get isDirty => arrayState.isDirty;

  /// Extracts all item values as `List<Map<K, Object?>>`.
  List<Map<K, Object?>> get values => arrayState.values;

  /// Index operator to access item form: `cubit[index]`.
  NeatFormState<K> operator [](int index) => arrayState[index];

  void _emitArrayState(NeatFormArrayState<K> newArrayState) {
    emit(updateArrayForm(state, newArrayState));
  }

  /// Adds an item to the array.
  void addItem([
    Map<K, Object?> initialValues = const {},
    Map<K, bool> optionalKeys = const {},
    String? id,
  ]) {
    _emitArrayState(
      _NeatFormArrayEngine.addItem<K>(
        state: arrayState,
        initialValues: initialValues,
        optionalKeys: optionalKeys,
        templateKeys: itemValidators.keys,
        id: id,
      ),
    );
  }

  /// Inserts an item at [index].
  void insertItem(
    int index, [
    Map<K, Object?> initialValues = const {},
    Map<K, bool> optionalKeys = const {},
    String? id,
  ]) {
    _emitArrayState(
      _NeatFormArrayEngine.insertItem<K>(
        state: arrayState,
        index: index,
        initialValues: initialValues,
        optionalKeys: optionalKeys,
        templateKeys: itemValidators.keys,
        id: id,
      ),
    );
  }

  /// Removes an item at [index].
  void removeItemAt(int index) {
    _emitArrayState(
      _NeatFormArrayEngine.removeItemAt<K>(
        state: arrayState,
        index: index,
      ),
    );
  }

  /// Removes an item by [id].
  void removeItemById(String id) {
    _emitArrayState(
      _NeatFormArrayEngine.removeItemById<K>(
        state: arrayState,
        id: id,
      ),
    );
  }

  /// Removes all items matching the provided [test] predicate.
  void removeWhere(bool Function(NeatFormArrayItem<K> item) test) {
    _emitArrayState(_NeatFormArrayEngine.removeWhere<K>(state: arrayState, test: test));
  }

  /// Clears all items in the array.
  void clearItems() {
    _emitArrayState(_NeatFormArrayEngine.clearItems<K>(state: arrayState));
  }

  /// Replaces all items in the array with a new [valuesList].
  void setItems(
    List<Map<K, Object?>> valuesList, {
    Map<K, bool> optionalKeys = const {},
  }) {
    _emitArrayState(
      _NeatFormArrayEngine.setItems<K>(
        state: arrayState,
        valuesList: valuesList,
        optionalKeys: optionalKeys,
        templateKeys: itemValidators.keys,
      ),
    );
  }

  /// Moves an item from [fromIndex] to [toIndex].
  void moveItem(int fromIndex, int toIndex) {
    _emitArrayState(
      _NeatFormArrayEngine.moveItem<K>(
        state: arrayState,
        fromIndex: fromIndex,
        toIndex: toIndex,
      ),
    );
  }

  /// Updates a field in the sub-form at [itemIndex].
  void setArrayField<T>(
    int itemIndex,
    K key,
    T value, {
    bool touch = true,
    bool clearError = true,
  }) {
    _emitArrayState(
      _NeatFormArrayEngine.setArrayField<T, K>(
        state: arrayState,
        itemIndex: itemIndex,
        key: key,
        value: value,
        touch: touch,
        clearError: clearError,
      ),
    );
  }

  /// Sets and validates a field in the sub-form at [itemIndex] immediately.
  void setAndValidateArrayField<T>(
    int itemIndex,
    K key,
    T value, {
    NeatValidator<T>? validator,
    bool touch = true,
  }) {
    _emitArrayState(
      _NeatFormArrayEngine.setAndValidateArrayField<T, K>(
        state: arrayState,
        itemValidators: itemValidators,
        itemIndex: itemIndex,
        key: key,
        value: value,
        validator: validator,
        touch: touch,
      ),
    );
  }

  /// Validates all sub-forms and array-level validators.
  bool validateArray() {
    final (newState, isValid) = _NeatFormArrayEngine.validateArray<K>(
      state: arrayState,
      itemValidators: itemValidators,
      arrayValidators: arrayValidators,
    );
    _emitArrayState(newState);
    return isValid;
  }

  /// Submits the form array if valid.
  Future<bool> submitForm({
    required Future<void> Function(List<Map<K, Object?>> values) onSubmit,
    void Function(NeatValidationError? arrayError, List<Map<K, NeatValidationError>> itemErrors)? onError,
  }) async {
    final isValid = validateArray();
    if (!isValid) {
      _emitArrayState(arrayState.copyWith(status: NeatSubmissionStatus.failure));
      if (onError != null) {
        final itemErrors = arrayState.items.map((item) {
          final errs = <K, NeatValidationError>{};
          for (final entry in item.form.fields.entries) {
            if (entry.value.error != null) {
              errs[entry.key] = entry.value.error!;
            }
          }
          return errs;
        }).toList();
        onError(arrayState.error, itemErrors);
      }
      return false;
    }

    _emitArrayState(arrayState.copyWith(status: NeatSubmissionStatus.submitting));

    try {
      await onSubmit(values);
      _emitArrayState(arrayState.copyWith(status: NeatSubmissionStatus.success));
      return true;
    } on Exception {
      _emitArrayState(arrayState.copyWith(status: NeatSubmissionStatus.failure));
      rethrow;
    } catch (_) {
      _emitArrayState(arrayState.copyWith(status: NeatSubmissionStatus.failure));
      rethrow;
    }
  }

  /// Resets the array to its initial state.
  void resetArray() {
    _emitArrayState(_NeatFormArrayEngine.resetArray<K>(state: arrayState));
  }
}
