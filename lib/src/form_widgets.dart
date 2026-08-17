import 'dart:async';

import 'package:flutter/material.dart';
import 'package:neat_form/src/field_state.dart';
import 'package:neat_form/src/form_array.dart';
import 'package:neat_form/src/form_controller.dart';

// =============================================================================
// TYPEDEFS
// =============================================================================

/// Signature for a widget builder that receives a [NeatFieldState] and its parent [NeatFormController].
typedef NeatFieldWidgetBuilder<K, T> = Widget Function(
  BuildContext context,
  NeatFieldState<T> fieldState,
  NeatFormController<K> controller,
);

/// Signature for a widget builder that receives only a [NeatFieldState].
typedef NeatFieldStateWidgetBuilder<T> = Widget Function(
  BuildContext context,
  NeatFieldState<T> fieldState,
);

/// Condition predicate to determine if [NeatFieldBuilder] should rebuild.
typedef NeatFieldBuildWhen<T> = bool Function(
  NeatFieldState<T> previous,
  NeatFieldState<T> current,
);

/// Signature for a widget builder that receives a [NeatFormState] and its [NeatFormController].
typedef NeatFormWidgetBuilder<K> = Widget Function(
  BuildContext context,
  NeatFormState<K> formState,
  NeatFormController<K> controller,
);

/// Condition predicate to determine if [NeatFormBuilder] should rebuild.
typedef NeatFormBuildWhen<K> = bool Function(
  NeatFormState<K> previous,
  NeatFormState<K> current,
);

/// Signature for a widget builder that receives a [NeatFormArrayState] and its [NeatFormArrayController].
typedef NeatFormArrayWidgetBuilder<K> = Widget Function(
  BuildContext context,
  NeatFormArrayState<K> arrayState,
  NeatFormArrayController<K> controller,
);

/// Condition predicate to determine if [NeatFormArrayBuilder] should rebuild.
typedef NeatFormArrayBuildWhen<K> = bool Function(
  NeatFormArrayState<K> previous,
  NeatFormArrayState<K> current,
);

// =============================================================================
// 1. NEAT FORM SCOPE (INHERITED WIDGETS)
// =============================================================================

/// An [InheritedWidget] that provides a [NeatFormController] to descendant widgets.
///
/// Use [NeatFormScope.of] or [NeatFormScope.maybeOf] to retrieve the nearest controller.
///
/// Example:
/// ```dart
/// NeatFormScope<LoginForm>(
///   controller: _loginController,
///   child: Column(
///     children: [
///       NeatFieldBuilder<LoginForm, String>(
///         field: LoginForm.email,
///         builder: (context, state, controller) => TextField(...),
///       ),
///     ],
///   ),
/// )
/// ```
class NeatFormScope<K> extends InheritedWidget {
  /// Creates a [NeatFormScope].
  const NeatFormScope({
    required this.controller,
    required super.child,
    super.key,
  });

  /// The form controller exposed to descendants.
  final NeatFormController<K> controller;

  /// Obtains the nearest [NeatFormController] of type [K] up in the widget tree.
  ///
  /// Throws a [FlutterError] if no [NeatFormScope] of type [K] is found.
  static NeatFormController<K> of<K>(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NeatFormScope<K>>();
    if (scope == null) {
      throw FlutterError(
        'NeatFormScope.of() called with a context that does not contain a NeatFormScope<$K>.\n'
        'No NeatFormScope<$K> ancestor could be found starting from the context that was passed to NeatFormScope.of<$K>().\n'
        'Ensure that a NeatFormScope<$K> is an ancestor of the widget calling NeatFormScope.of<$K>().',
      );
    }
    return scope.controller;
  }

  /// Obtains the nearest [NeatFormController] of type [K], or `null` if none is found.
  static NeatFormController<K>? maybeOf<K>(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NeatFormScope<K>>();
    return scope?.controller;
  }

  @override
  bool updateShouldNotify(NeatFormScope<K> oldWidget) {
    return controller != oldWidget.controller;
  }
}

/// An [InheritedWidget] that provides a [NeatFormArrayController] to descendant widgets.
///
/// Use [NeatFormArrayScope.of] or [NeatFormArrayScope.maybeOf] to retrieve the nearest array controller.
class NeatFormArrayScope<K> extends InheritedWidget {
  /// Creates a [NeatFormArrayScope].
  const NeatFormArrayScope({
    required this.controller,
    required super.child,
    super.key,
  });

  /// The dynamic form array controller exposed to descendants.
  final NeatFormArrayController<K> controller;

  /// Obtains the nearest [NeatFormArrayController] of type [K] up in the widget tree.
  ///
  /// Throws a [FlutterError] if no [NeatFormArrayScope] of type [K] is found.
  static NeatFormArrayController<K> of<K>(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<NeatFormArrayScope<K>>();
    if (scope == null) {
      throw FlutterError(
        'NeatFormArrayScope.of() called with a context that does not contain a NeatFormArrayScope<$K>.\n'
        'No NeatFormArrayScope<$K> ancestor could be found starting from the context that was passed to NeatFormArrayScope.of<$K>().\n'
        'Ensure that a NeatFormArrayScope<$K> is an ancestor of the widget calling NeatFormArrayScope.of<$K>().',
      );
    }
    return scope.controller;
  }

  /// Obtains the nearest [NeatFormArrayController] of type [K], or `null` if none is found.
  static NeatFormArrayController<K>? maybeOf<K>(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<NeatFormArrayScope<K>>();
    return scope?.controller;
  }

  @override
  bool updateShouldNotify(NeatFormArrayScope<K> oldWidget) {
    return controller != oldWidget.controller;
  }
}

// =============================================================================
// 2. NEAT FIELD BUILDER (FINE-GRAINED REACTIVITY)
// =============================================================================

/// A fine-grained reactive widget that listens to a single form field [field]
/// and only rebuilds when that field's state changes.
///
/// If [controller] is omitted, it will automatically look up the nearest
/// [NeatFormScope] of type [K] in the widget tree.
///
/// Example:
/// ```dart
/// NeatFieldBuilder<LoginForm, String>(
///   field: LoginForm.email,
///   builder: (context, fieldState, controller) {
///     return TextField(
///       decoration: InputDecoration(
///         labelText: 'Email',
///         errorText: fieldState.errorMessage,
///       ),
///       onChanged: (v) => controller.setField(LoginForm.email, v),
///     );
///   },
/// )
/// ```
class NeatFieldBuilder<K, T> extends StatefulWidget {
  /// Creates a [NeatFieldBuilder] bound to a [field] on a [NeatFormController].
  const NeatFieldBuilder({
    required this.field,
    required this.builder,
    this.controller,
    this.buildWhen,
    super.key,
  });

  /// The field key to observe.
  final K field;

  /// The builder function invoked to construct the widget tree for this field.
  final NeatFieldWidgetBuilder<K, T> builder;

  /// Explicit controller to listen to. If null, resolves from [NeatFormScope].
  final NeatFormController<K>? controller;

  /// Optional condition to control whether this field widget should rebuild.
  final NeatFieldBuildWhen<T>? buildWhen;

  @override
  State<NeatFieldBuilder<K, T>> createState() => _NeatFieldBuilderState<K, T>();
}

class _NeatFieldBuilderState<K, T> extends State<NeatFieldBuilder<K, T>> {
  NeatFormController<K>? _controller;
  late NeatFieldState<T> _lastState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final effectiveController =
        widget.controller ?? NeatFormScope.maybeOf<K>(context);
    if (_controller != effectiveController) {
      _controller?.removeListener(_onControllerChanged);
      _controller = effectiveController;
      if (_controller != null) {
        _lastState = _controller!.field<T>(widget.field);
        _controller!.addListener(_onControllerChanged);
      }
    }
  }

  @override
  void didUpdateWidget(NeatFieldBuilder<K, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controllerChanged = widget.controller != oldWidget.controller;
    final fieldChanged = widget.field != oldWidget.field;

    if (controllerChanged) {
      _controller?.removeListener(_onControllerChanged);
      _controller = widget.controller ?? NeatFormScope.maybeOf<K>(context);
      if (_controller != null) {
        _lastState = _controller!.field<T>(widget.field);
        _controller!.addListener(_onControllerChanged);
      }
    } else if (fieldChanged) {
      if (_controller != null) {
        _lastState = _controller!.field<T>(widget.field);
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (_controller == null || !mounted) return;
    final previousState = _lastState;
    final newState = _controller!.field<T>(widget.field);
    _lastState = newState;
    final shouldRebuild =
        widget.buildWhen?.call(previousState, newState) ??
            (previousState != newState);
    if (shouldRebuild) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      throw FlutterError(
        'NeatFieldBuilder<$K, $T> could not find a NeatFormController<$K>.\n'
        'Either provide an explicit controller or wrap your widget in a NeatFormScope<$K>.',
      );
    }
    return widget.builder(context, _lastState, _controller!);
  }
}

// =============================================================================
// 3. NEAT FORM BUILDER (FORM-LEVEL REACTIVITY)
// =============================================================================

/// A widget that rebuilds when the form's overall state ([NeatFormState]) changes.
///
/// Useful for observing form-level validity, submission status, or overall error messages.
///
/// Example:
/// ```dart
/// NeatFormBuilder<LoginForm>(
///   builder: (context, formState, controller) {
///     return Column(
///       children: [
///         if (formState.errorMessage != null)
///           Text(formState.errorMessage!, style: const TextStyle(color: Colors.red)),
///         ElevatedButton(
///           onPressed: formState.isValid ? () => controller.submitForm(...) : null,
///           child: const Text('Submit'),
///         ),
///       ],
///     );
///   },
/// )
/// ```
class NeatFormBuilder<K> extends StatefulWidget {
  /// Creates a [NeatFormBuilder].
  const NeatFormBuilder({
    required this.builder,
    this.controller,
    this.buildWhen,
    super.key,
  });

  /// The builder function invoked to construct the widget tree for the form state.
  final NeatFormWidgetBuilder<K> builder;

  /// Explicit controller to listen to. If null, resolves from [NeatFormScope].
  final NeatFormController<K>? controller;

  /// Optional condition to control whether this form widget should rebuild.
  final NeatFormBuildWhen<K>? buildWhen;

  @override
  State<NeatFormBuilder<K>> createState() => _NeatFormBuilderState<K>();
}

class _NeatFormBuilderState<K> extends State<NeatFormBuilder<K>> {
  NeatFormController<K>? _controller;
  late NeatFormState<K> _lastState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final effectiveController =
        widget.controller ?? NeatFormScope.maybeOf<K>(context);
    if (_controller != effectiveController) {
      _controller?.removeListener(_onControllerChanged);
      _controller = effectiveController;
      if (_controller != null) {
        _lastState = _controller!.state;
        _controller!.addListener(_onControllerChanged);
      }
    }
  }

  @override
  void didUpdateWidget(NeatFormBuilder<K> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller?.removeListener(_onControllerChanged);
      _controller = widget.controller ?? NeatFormScope.maybeOf<K>(context);
      if (_controller != null) {
        _lastState = _controller!.state;
        _controller!.addListener(_onControllerChanged);
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (_controller == null || !mounted) return;
    final previousState = _lastState;
    final newState = _controller!.state;
    _lastState = newState;
    final shouldRebuild =
        widget.buildWhen?.call(previousState, newState) ??
            (previousState != newState);
    if (shouldRebuild) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      throw FlutterError(
        'NeatFormBuilder<$K> could not find a NeatFormController<$K>.\n'
        'Either provide an explicit controller or wrap your widget in a NeatFormScope<$K>.',
      );
    }
    return widget.builder(context, _lastState, _controller!);
  }
}

// =============================================================================
// 4. NEAT FORM ARRAY BUILDER (DYNAMIC ARRAY REACTIVITY)
// =============================================================================

/// A widget that rebuilds when a [NeatFormArrayController]'s state changes
/// (e.g. items added, removed, reordered, or array-level error updated).
///
/// Example:
/// ```dart
/// NeatFormArrayBuilder<GuestField>(
///   builder: (context, arrayState, arrayController) {
///     return Column(
///       children: [
///         Text('Guests: ${arrayState.length}'),
///         ...arrayState.items.map((item) => ...),
///         ElevatedButton(
///           onPressed: () => arrayController.addItem(),
///           child: const Text('Add Guest'),
///         ),
///       ],
///     );
///   },
/// )
/// ```
class NeatFormArrayBuilder<K> extends StatefulWidget {
  /// Creates a [NeatFormArrayBuilder].
  const NeatFormArrayBuilder({
    required this.builder,
    this.controller,
    this.buildWhen,
    super.key,
  });

  /// The builder function invoked to construct the dynamic form array UI.
  final NeatFormArrayWidgetBuilder<K> builder;

  /// Explicit array controller. If null, resolves from [NeatFormArrayScope].
  final NeatFormArrayController<K>? controller;

  /// Optional condition to control whether this array widget should rebuild.
  final NeatFormArrayBuildWhen<K>? buildWhen;

  @override
  State<NeatFormArrayBuilder<K>> createState() =>
      _NeatFormArrayBuilderState<K>();
}

class _NeatFormArrayBuilderState<K> extends State<NeatFormArrayBuilder<K>> {
  NeatFormArrayController<K>? _controller;
  late NeatFormArrayState<K> _lastState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final effectiveController =
        widget.controller ?? NeatFormArrayScope.maybeOf<K>(context);
    if (_controller != effectiveController) {
      _controller?.removeListener(_onControllerChanged);
      _controller = effectiveController;
      if (_controller != null) {
        _lastState = _controller!.state;
        _controller!.addListener(_onControllerChanged);
      }
    }
  }

  @override
  void didUpdateWidget(NeatFormArrayBuilder<K> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller?.removeListener(_onControllerChanged);
      _controller = widget.controller ?? NeatFormArrayScope.maybeOf<K>(context);
      if (_controller != null) {
        _lastState = _controller!.state;
        _controller!.addListener(_onControllerChanged);
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (_controller == null || !mounted) return;
    final previousState = _lastState;
    final newState = _controller!.state;
    _lastState = newState;
    final shouldRebuild =
        widget.buildWhen?.call(previousState, newState) ??
            (previousState != newState);
    if (shouldRebuild) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      throw FlutterError(
        'NeatFormArrayBuilder<$K> could not find a NeatFormArrayController<$K>.\n'
        'Either provide an explicit controller or wrap your widget in a NeatFormArrayScope<$K>.',
      );
    }
    return widget.builder(context, _lastState, _controller!);
  }
}

// =============================================================================
// 5. NEAT SUBMIT BUTTON (STATE-AWARE BUTTON)
// =============================================================================

/// A button widget that automatically binds to a [NeatFormController]'s submission
/// and validation states.
///
/// Features:
/// - Automatically displays [loadingWidget] (defaults to a circular spinner) when `isSubmitting`.
/// - Can automatically disable when `isValid == false` if [disableWhenInvalid] is `true`.
/// - Provides the [NeatFormController] directly in [onPressed].
///
/// Example:
/// ```dart
/// NeatSubmitButton<LoginForm>(
///   onPressed: (controller) async {
///     await controller.submitForm(
///       onSuccess: (values) => print('Logged in!'),
///     );
///   },
///   child: const Text('Đăng Nhập'),
/// )
/// ```
class NeatSubmitButton<K> extends StatelessWidget {
  /// Creates a [NeatSubmitButton].
  const NeatSubmitButton({
    required this.child,
    this.controller,
    this.onPressed,
    this.loadingWidget,
    this.disableWhenInvalid = false,
    this.disableWhenSubmitting = true,
    this.style,
    super.key,
  });

  /// The button label or widget when not loading.
  final Widget child;

  /// Explicit controller. If null, resolves from [NeatFormScope].
  final NeatFormController<K>? controller;

  /// Callback executed when the button is tapped. Receives the active [NeatFormController].
  final FutureOr<void> Function(NeatFormController<K> controller)? onPressed;

  /// Custom widget displayed while the form is submitting.
  /// Defaults to a 20x20 [CircularProgressIndicator].
  final Widget? loadingWidget;

  /// If `true`, the button is disabled when `controller.state.isValid` is `false`.
  /// Default is `false`.
  final bool disableWhenInvalid;

  /// If `true`, the button is disabled while `controller.state.submissionStatus.isSubmitting`.
  /// Default is `true`.
  final bool disableWhenSubmitting;

  /// Optional button style.
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return NeatFormBuilder<K>(
      controller: controller,
      buildWhen: (prev, curr) {
        return prev.submissionStatus != curr.submissionStatus ||
            (disableWhenInvalid && prev.isValid != curr.isValid);
      },
      builder: (context, formState, formController) {
        final isSubmitting = formState.submissionStatus.isSubmitting;
        final isDisabled = (disableWhenSubmitting && isSubmitting) ||
            (disableWhenInvalid && !formState.isValid) ||
            onPressed == null;

        return ElevatedButton(
          style: style,
          onPressed: isDisabled ? null : () => onPressed!(formController),
          child: isSubmitting
              ? (loadingWidget ??
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ))
              : child,
        );
      },
    );
  }
}
