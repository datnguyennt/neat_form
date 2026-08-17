import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:neat_form/src/devtools/neat_form_registry.dart';

/// Bridge that connects `neat_form` core engine to Flutter DevTools via Dart VM Service.
class NeatFormDevToolsBridge {
  NeatFormDevToolsBridge._();

  static bool _initialized = false;

  /// Initializes the bridge and registers all VM Service extensions.
  ///
  /// Safe to call multiple times. Automatically no-ops in release mode (`kReleaseMode`).
  static void init() {
    if (_initialized || kReleaseMode) return;
    _initialized = true;

    _registerServiceExtensions();
  }

  /// Broadcasts a form-related event to Flutter DevTools over the `neat_form:event` stream.
  static void postEvent(String kind, Map<String, dynamic> data) {
    if (kReleaseMode) return;

    try {
      dev.postEvent('neat_form:event', {
        'kind': kind,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        ...data,
      });
    } on Object catch (_) {
      // Ignored if developer service is not attached.
    }
  }

  /// Handles incoming service extension calls dispatched from DevTools or test harness.
  static Future<dev.ServiceExtensionResponse> handleServiceExtensionCall(
    String method,
    Map<String, String> parameters,
  ) async {
    switch (method) {
      case 'ext.neat_form.getForms':
        final forms = NeatFormDevToolsRegistry.instance.activeForms;
        return dev.ServiceExtensionResponse.result(
          jsonEncode({'forms': forms}),
        );

      case 'ext.neat_form.getFormDetails':
        final formId = parameters['formId'];
        if (formId == null || formId.isEmpty) {
          return dev.ServiceExtensionResponse.error(
            dev.ServiceExtensionResponse.invalidParams,
            'Missing "formId" parameter',
          );
        }

        final details = NeatFormDevToolsRegistry.instance.getFormDetails(formId);
        if (details == null) {
          return dev.ServiceExtensionResponse.error(
            dev.ServiceExtensionResponse.invalidParams,
            'Form with ID "$formId" not found or has been disposed',
          );
        }

        return dev.ServiceExtensionResponse.result(jsonEncode(details));

      case 'ext.neat_form.setFieldValue':
        final formId = parameters['formId'];
        final key = parameters['key'];
        final rawValue = parameters['value'];

        if (formId == null || key == null) {
          return dev.ServiceExtensionResponse.error(
            dev.ServiceExtensionResponse.invalidParams,
            'Missing "formId" or "key" parameter',
          );
        }

        Object? parsedValue = rawValue;
        if (rawValue != null && (rawValue.startsWith('{') || rawValue.startsWith('['))) {
          try {
            parsedValue = jsonDecode(rawValue);
          } on Object catch (_) {}
        }

        final success = NeatFormDevToolsRegistry.instance.setFieldValue(
          formId,
          key,
          parsedValue,
        );

        if (!success) {
          return dev.ServiceExtensionResponse.error(
            dev.ServiceExtensionResponse.invalidParams,
            'Could not update field "$key" on form "$formId"',
          );
        }

        return dev.ServiceExtensionResponse.result(
          jsonEncode({'success': true}),
        );

      case 'ext.neat_form.validateForm':
        final formId = parameters['formId'];
        if (formId == null) {
          return dev.ServiceExtensionResponse.error(
            dev.ServiceExtensionResponse.invalidParams,
            'Missing "formId" parameter',
          );
        }

        final success = NeatFormDevToolsRegistry.instance.validateForm(formId);
        return dev.ServiceExtensionResponse.result(
          jsonEncode({'success': success}),
        );

      case 'ext.neat_form.resetForm':
        final formId = parameters['formId'];
        if (formId == null) {
          return dev.ServiceExtensionResponse.error(
            dev.ServiceExtensionResponse.invalidParams,
            'Missing "formId" parameter',
          );
        }

        final success = NeatFormDevToolsRegistry.instance.resetForm(formId);
        return dev.ServiceExtensionResponse.result(
          jsonEncode({'success': success}),
        );

      case 'ext.neat_form.autofillMock':
        final formId = parameters['formId'];
        if (formId == null) {
          return dev.ServiceExtensionResponse.error(
            dev.ServiceExtensionResponse.invalidParams,
            'Missing "formId" parameter',
          );
        }

        final mode = parameters['mode'] ?? 'valid';
        final success = NeatFormDevToolsRegistry.instance.autofillMockData(
          formId,
          mode: mode,
        );
        return dev.ServiceExtensionResponse.result(
          jsonEncode({'success': success}),
        );

      case 'ext.neat_form.importState':
        final formId = parameters['formId'];
        final rawData = parameters['values'];
        if (formId == null || rawData == null) {
          return dev.ServiceExtensionResponse.error(
            dev.ServiceExtensionResponse.invalidParams,
            'Missing "formId" or "values" parameter',
          );
        }

        Map<String, dynamic> parsedValues;
        try {
          final decoded = jsonDecode(rawData);
          if (decoded is Map<String, dynamic>) {
            parsedValues = decoded;
          } else if (decoded is Map) {
            parsedValues = decoded.cast<String, dynamic>();
          } else {
            return dev.ServiceExtensionResponse.error(
              dev.ServiceExtensionResponse.invalidParams,
              '"values" must be a JSON object',
            );
          }
        } on Object catch (e) {
          return dev.ServiceExtensionResponse.error(
            dev.ServiceExtensionResponse.invalidParams,
            'Malformed JSON: $e',
          );
        }

        final success = NeatFormDevToolsRegistry.instance.importJsonState(
          formId,
          parsedValues,
        );
        return dev.ServiceExtensionResponse.result(
          jsonEncode({'success': success}),
        );

      default:
        return dev.ServiceExtensionResponse.error(
          dev.ServiceExtensionResponse.extensionError,
          'Unknown method "$method"',
        );
    }
  }

  static void _registerServiceExtensions() {
    final methods = [
      'ext.neat_form.getForms',
      'ext.neat_form.getFormDetails',
      'ext.neat_form.setFieldValue',
      'ext.neat_form.validateForm',
      'ext.neat_form.resetForm',
      'ext.neat_form.autofillMock',
      'ext.neat_form.importState',
    ];

    for (final method in methods) {
      try {
        dev.registerExtension(method, handleServiceExtensionCall);
      } on Object catch (_) {}
    }
  }
}
