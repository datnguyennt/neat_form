# 1.0.0

- Initial stable release of `neat_form` for Flutter & Dart.
- **Pure Core Logic & Zero UI Coupling:** Pure Dart state models and validators.
- **Native Flutter Integration:** `NeatFormController` extends `ChangeNotifier` / `Listenable` for direct usage with `ListenableBuilder` or `AnimatedBuilder`.
- **Strict Type Safety:** 100% `Object?` type safety without `dynamic` calls.
- **State Management Agnostic:** Seamless integration with Riverpod, BLoC, Cubit, or vanilla Flutter via `NeatFormMixin`.
- **25+ Built-in Validators:**
  - Strings: `required()`, `notBlank()`, `exactLength()`, `minLength()`, `maxLength()`, `lengthRange()`, `startsWith()`, `endsWith()`, `contains()`, `notContains()`, `latinOnly()`, `noEmoji()`.
  - Format & Security: `email()`, `phone()`, `passwordStrength()`, `creditCard()` (Luhn Algorithm), `url()`, `numeric()`, `alphanumericOnly()`, `noSpecialChars()`, `noSpaces()`, `blacklist()`, `noHtml()` (anti-XSS).
  - Numeric: `minValue()`, `maxValue()`, `positive()`, `negative()`, `multipleOf()`, `decimalPrecision()`.
  - DateTime: `pastDate()`, `futureDate()`, `dateRange()`.
  - Consent: `mustBeTrue()`, `mustBeFalse()`.
  - Collections: `minItems()`, `maxItems()`, `uniqueItems()`.
  - Combinators: `match()`, `when()`, `combine()`, `custom()`.
- **Async Validation with Race Condition Protection:** Sequence tokens guarantee stale async results never overwrite newer user input.
- **Submission Lifecycle:** Integrated `submissionStatus` (`idle`, `submitting`, `success`, `failure`).
- **Decoupled Localization:** `NeatErrorResolver` with token template parameter interpolation (e.g. `{minLength}`).
- **Interactive Multi-Platform Example App:** Full Flutter showcase supporting iOS, Android, macOS, and Web.
