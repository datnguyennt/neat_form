import 'dart:async';
import 'dart:convert';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:neat_form_devtools_extension/src/models/form_details.dart';
import 'package:neat_form_devtools_extension/src/models/form_event.dart';
import 'package:neat_form_devtools_extension/src/models/form_summary.dart';

/// Function signature for invoking service extensions on the VM Service.
typedef ServiceExtensionCaller = Future<Map<String, dynamic>?> Function(
  String method, {
  Map<String, dynamic>? args,
});

/// Controller responsible for managing DevTools RPC communication and real-time state.
class DevToolsServiceController {
  DevToolsServiceController({ServiceExtensionCaller? serviceCaller})
      : _serviceCaller = serviceCaller;

  final ServiceExtensionCaller? _serviceCaller;

  final ValueNotifier<List<FormSummary>> formsNotifier = ValueNotifier([]);
  final ValueNotifier<FormDetails?> selectedFormNotifier = ValueNotifier(null);
  final ValueNotifier<List<FormEvent>> eventsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  String? _selectedFormId;
  StreamSubscription? _eventSubscription;
  Timer? _pollingTimer;

  String? get selectedFormId => _selectedFormId;

  /// Initializes the service controller, sets up event streams, and triggers initial load.
  void init() {
    _subscribeToEvents();
    fetchForms();

    // Periodic safety poll every 3 seconds to keep forms list synchronized
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      fetchForms(silent: true);
      if (_selectedFormId != null) {
        fetchSelectedFormDetails(silent: true);
      }
    });
  }

  Future<Map<String, dynamic>?> _callService(
    String method, {
    Map<String, dynamic>? args,
  }) async {
    if (_serviceCaller != null) {
      return _serviceCaller(method, args: args);
    }

    final service = serviceManager.service;
    if (service == null) return null;

    final response = await service.callServiceExtension(method, args: args);
    return response.json;
  }

  void _subscribeToEvents() {
    try {
      final service = serviceManager.service;
      _eventSubscription = service?.onExtensionEvent.listen((event) {
        if (event.extensionKind == 'neat_form:event' && event.extensionData?.data != null) {
          handleIncomingEvent(event.extensionData!.data);
        }
      });
    } on Object catch (e) {
      errorNotifier.value = 'Failed to subscribe to extension events: $e';
    }
  }

  /// Processes an incoming event map from VM service or test mock.
  void handleIncomingEvent(Map<String, dynamic> data) {
    final formEvent = FormEvent.fromJson(data);

    // Add to events history (cap at 100 most recent events)
    final currentEvents = List<FormEvent>.from(eventsNotifier.value);
    currentEvents.insert(0, formEvent);
    if (currentEvents.length > 100) {
      currentEvents.removeLast();
    }
    eventsNotifier.value = currentEvents;

    // React to lifecycle events
    if (formEvent.kind == 'form_registered' || formEvent.kind == 'form_unregistered') {
      fetchForms(silent: true);
    } else if (formEvent.formId == _selectedFormId) {
      fetchSelectedFormDetails(silent: true);
    }
  }

  /// Fetches the list of active forms from the connected Flutter application.
  Future<void> fetchForms({bool silent = false}) async {
    if (!silent) isLoadingNotifier.value = true;
    errorNotifier.value = null;

    try {
      final json = await _callService('ext.neat_form.getForms');
      if (json == null) {
        if (!silent) errorNotifier.value = 'VM Service is not connected.';
        return;
      }

      final formsList = (json['forms'] as List<dynamic>? ?? [])
          .map((e) => FormSummary.fromJson(e as Map<String, dynamic>))
          .toList();

      formsNotifier.value = formsList;

      // Auto-select first form if none selected or selected form was disposed
      if (formsList.isNotEmpty) {
        if (_selectedFormId == null || !formsList.any((f) => f.id == _selectedFormId)) {
          selectForm(formsList.first.id);
        }
      } else {
        _selectedFormId = null;
        selectedFormNotifier.value = null;
      }
    } on Object catch (e) {
      if (!silent) errorNotifier.value = 'Error fetching forms: $e';
    } finally {
      if (!silent) isLoadingNotifier.value = false;
    }
  }

  /// Selects a specific form and loads its detailed state.
  Future<void> selectForm(String formId) async {
    _selectedFormId = formId;
    await fetchSelectedFormDetails();
  }

  /// Fetches deep details for the currently selected form.
  Future<void> fetchSelectedFormDetails({bool silent = false}) async {
    if (_selectedFormId == null) return;
    if (!silent) isLoadingNotifier.value = true;

    try {
      final json = await _callService(
        'ext.neat_form.getFormDetails',
        args: {'formId': _selectedFormId!},
      );

      if (json != null) {
        selectedFormNotifier.value = FormDetails.fromJson(json);
      }
    } on Object catch (e) {
      if (!silent) errorNotifier.value = 'Error loading form details: $e';
    } finally {
      if (!silent) isLoadingNotifier.value = false;
    }
  }

  /// Updates a field value remotely on the connected application.
  Future<bool> setFieldValue(String key, dynamic value) async {
    if (_selectedFormId == null) return false;

    try {
      final valueStr = value is String ? value : jsonEncode(value);
      final json = await _callService(
        'ext.neat_form.setFieldValue',
        args: {
          'formId': _selectedFormId!,
          'key': key,
          'value': valueStr,
        },
      );

      final success = json?['success'] as bool? ?? false;
      if (success) {
        await fetchSelectedFormDetails(silent: true);
      }
      return success;
    } on Object catch (e) {
      errorNotifier.value = 'Failed to set field value: $e';
      return false;
    }
  }

  /// Triggers form validation on the connected application.
  Future<bool> validateCurrentForm() async {
    if (_selectedFormId == null) return false;

    try {
      final json = await _callService(
        'ext.neat_form.validateForm',
        args: {'formId': _selectedFormId!},
      );

      final success = json?['success'] as bool? ?? false;
      await fetchSelectedFormDetails(silent: true);
      return success;
    } on Object catch (e) {
      errorNotifier.value = 'Validation failed: $e';
      return false;
    }
  }

  /// Resets the current form to its initial state.
  Future<bool> resetCurrentForm() async {
    if (_selectedFormId == null) return false;

    try {
      final json = await _callService(
        'ext.neat_form.resetForm',
        args: {'formId': _selectedFormId!},
      );

      final success = json?['success'] as bool? ?? false;
      await fetchSelectedFormDetails(silent: true);
      return success;
    } on Object catch (e) {
      errorNotifier.value = 'Reset failed: $e';
      return false;
    }
  }

  /// Automatically fills mock test data into the current form.
  Future<bool> autofillMockData({String mode = 'valid'}) async {
    if (_selectedFormId == null) return false;

    try {
      final json = await _callService(
        'ext.neat_form.autofillMock',
        args: {
          'formId': _selectedFormId!,
          'mode': mode,
        },
      );

      final success = json?['success'] as bool? ?? false;
      await fetchSelectedFormDetails(silent: true);
      return success;
    } on Object catch (e) {
      errorNotifier.value = 'Autofill failed: $e';
      return false;
    }
  }

  /// Automatically fills invalid or boundary test data into the current form.
  Future<bool> autofillBoundaryData() => autofillMockData(mode: 'boundary');

  /// Imports a map of values to bulk-update fields on the connected form.
  Future<bool> importJsonState(Map<String, dynamic> values) async {
    if (_selectedFormId == null) return false;

    try {
      final json = await _callService(
        'ext.neat_form.importState',
        args: {
          'formId': _selectedFormId!,
          'values': jsonEncode(values),
        },
      );

      final success = json?['success'] as bool? ?? false;
      await fetchSelectedFormDetails(silent: true);
      return success;
    } on Object catch (e) {
      errorNotifier.value = 'State import failed: $e';
      return false;
    }
  }

  /// Clears the recorded event timeline.
  void clearEvents() {
    eventsNotifier.value = [];
  }

  /// Disposes resources, timers, and subscriptions.
  void dispose() {
    _eventSubscription?.cancel();
    _pollingTimer?.cancel();
    formsNotifier.dispose();
    selectedFormNotifier.dispose();
    eventsNotifier.dispose();
    isLoadingNotifier.dispose();
    errorNotifier.dispose();
  }
}
