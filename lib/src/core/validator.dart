import 'package:neat_form/src/core/validation_error.dart';

/// A synchronous validator function that inspects a value of type [T]
/// and returns a [NeatValidationError] if invalid, or `null` if valid.
typedef NeatValidator<T> = NeatValidationError? Function(T? value);

/// An asynchronous validator function that inspects a value of type [T]
/// and returns a [Future] containing [NeatValidationError] if invalid, or `null` if valid.
typedef NeatAsyncValidator<T> = Future<NeatValidationError?> Function(T? value);
