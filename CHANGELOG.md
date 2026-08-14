# 1.1.0-preview.1

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
- **Enhanced Test Suite:** 72 unit and widget tests covering all validators and form interactions.

# 1.0.0

- Initial release of `neat_form`.
- Pure Dart state models (`NeatFieldState<T>`, `NeatValidationError`).
- Basic validators (`required`, `email`, `minLength`, `maxLength`, `minValue`, `maxValue`, `pattern`, `match`, `blacklist`).
- `NeatFormMixin<K>` for state-driven controllers and notifiers.
- `NeatFormFieldMapExtension` for querying and validating field maps.
- `NeatErrorResolver` for decoupled localization.
