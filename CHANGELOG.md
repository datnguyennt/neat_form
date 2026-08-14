# 1.1.0-preview.3

- **Direct Error Access on `NeatFieldState`:** Added `errorMessage` getter for clean binding directly to `InputDecoration.errorText`.
- **Expanded Test Coverage:** Added comprehensive nested state management tests (`test/nested_and_state_management_test.dart`) covering complex field updates, Riverpod/custom notifier bindings, and race condition handling (increasing test suite to 83+ tests).
- **Widget Test Compatibility:** Configured `InkRipple.splashFactory` in the showcase example app to avoid fragment shader decoding issues (`ink_sparkle.frag`) in headless and test environments.
- **Documentation & Examples:** Updated README and showcase code examples to reflect the latest clean API patterns.

# 1.1.0-preview.2

- **Ultra-Clean Riverpod Support:**
  - Added `NeatFormNotifierMixin<K>` to automatically bind state, eliminating all manual boilerplate overrides in `Notifier<NeatFormState<K>>`.
  - Added `NeatFormState.fromValues(...)` factory for 1-line form initialization.
  - Added `NeatFieldState.errorMessage` getter for clean binding directly to `InputDecoration.errorText`.
  - Added `s.field<T>(key)` and index operator `s[key]` shorthand queries.
- **25+ Built-in Type-Safe Validators:** Added exhaustive validation rules:
  - Strings: `notBlank()`, `exactLength()`, `startsWith()`, `endsWith()`, `contains()`, `notContains()`, `latinOnly()`, `noEmoji()`.
  - Security & Fintech: `passwordStrength()`, `creditCard()` (Luhn Algorithm), `noHtml()` (anti-XSS).
  - Numeric: `positive()`, `negative()`, `multipleOf()`, `decimalPrecision()`.
  - DateTime: `pastDate()`, `futureDate()`, `dateRange()`.
  - Consent: `mustBeTrue()`, `mustBeFalse()`.
  - Collections: `minItems()`, `maxItems()`, `uniqueItems()`.
- **100% `Object?` Type Safety:** Eliminated all `dynamic` calls across models, controllers, and validators.
- **Flutter Native Reactive Controller:** `NeatFormController` extends `ChangeNotifier` / `Listenable` for direct reactive usage with Flutter's `ListenableBuilder`.
- **Async Race Condition Protection:** Sequence tokens ensure stale in-flight async requests never overwrite newer user inputs upon reset or rapid typing.
- **Submission Lifecycle:** Added `NeatSubmissionStatus` (`idle`, `submitting`, `success`, `failure`).
- **Interactive Multi-Platform Example App:** Full Flutter showcase supporting iOS, Android, macOS, and Web.
- **Enhanced Test Suite:** 78 unit and widget tests covering all validators, state models, and form interactions.

# 1.0.0

- Initial release of `neat_form`.
- Pure Dart state models (`NeatFieldState<T>`, `NeatValidationError`).
- Basic validators (`required`, `email`, `minLength`, `maxLength`, `minValue`, `maxValue`, `pattern`, `match`, `blacklist`).
- `NeatFormMixin<K>` for state-driven controllers and notifiers.
- `NeatFormFieldMapExtension` for querying and validating field maps.
- `NeatErrorResolver` for decoupled localization.
