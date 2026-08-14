# 1.1.0

- **Async Validation Race Condition Protection:** `validateFieldAsync` now ensures results from stale in-flight requests are not applied if user input changes before resolution.
- **Enhanced `isDirty` calculation & Nullable Value Support:** Fixed `isDirty` calculation for nullable fields and supported explicit null values in `copyWith`.
- **New Validators:**
  - `NeatValidators.requiredWith` for parameterized required error messages and codes.
  - `NeatValidators.when` for conditional validation rules.
  - `NeatValidators.numeric` for int/decimal validation.
  - `NeatValidators.url` for HTTP/HTTPS web address validation.
- **Pure-Dart `NeatFormController`:** Added lightweight controller with listener subscriptions for vanilla Dart/Flutter projects without Riverpod or Bloc.
- **Form Reset API:** Added `resetField` and `resetForm` in `NeatFormMixin`.
- **Regex Performance:** Optimized pattern evaluations using `hasMatch`.
- **Pub.dev Polish:** Added example project, topics, issue tracker, and expanded test suite.

# 1.0.0

- Initial release of `neat_form`.
- Strongly typed `NeatFieldState<T>`.
- Core validators (`NeatValidators`) for required, email, length, numeric range, regex pattern, matching, blacklist.
- `NeatFormMixin<K>` for state-driven controllers and notifiers.
- `NeatFormFieldMapExtension` for querying and validating field maps.
- `NeatErrorResolver` for decoupled localization.
