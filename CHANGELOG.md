# 1.2.1

- **Pub.dev Documentation Enhancement:**
  - Embedded high-resolution vector SVG diagrams in `README.md` and `README_EN.md` for full rendering compatibility on pub.dev and mobile devices.
  - Preserved interactive Mermaid code blocks inside expandable `<details>` sections.

# 1.2.0

- **Built-in Input Formatters & Masking Suite (`NeatInputFormatters`):**
  - Added zero-dependency Flutter input formatters preserving accurate mid-string cursor placement.
  - `NeatCurrencyFormatter`: Real-time thousand/decimal separators, custom prefix/suffix, and numeric extractor (`getNumericValue() -> num?`).
  - `NeatCardFormatter`: Auto card brand detection (Visa, Mastercard, Amex, JCB, Discover), 4-4-4-4 / 4-6-5 chunking, and clean number extractor.
  - `NeatMaskFormatter`: Custom alphanumeric mask patterns with `getUnmaskedText()` helper.
  - `NeatDateFormatter`: Formats `dd/MM/yyyy`, `yyyy/MM/dd`, `mm/dd/yyyy`, and `mm/yy` with boundary clamping and `getParsedDate() -> DateTime?`.
  - Utility formatters: `uppercase()`, `lowercase()`, `latinOnly()`, `noSpaces()`.
- **Enhanced Example App:** Live demonstration of real-time currency formatting, payment card formatting, and date masking.
- **Comprehensive Test Suite:** 104 unit and widget tests passing with 0 warnings on `very_good_analysis`.

# 1.1.1

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
- **Interactive Multi-Platform Example App:** Full Flutter showcase supporting iOS, Android, macOS, and Web with `InkRipple.splashFactory` configured for widget test & headless compatibility.
- **Comprehensive Test Suite:** 83+ unit and widget tests covering all validators, nested state models, notifier bindings, and form interactions.

# 1.0.0

- Initial release of `neat_form`.
- Pure Dart state models (`NeatFieldState<T>`, `NeatValidationError`).
- Basic validators (`required`, `email`, `minLength`, `maxLength`, `minValue`, `maxValue`, `pattern`, `match`, `blacklist`).
- `NeatFormMixin<K>` for state-driven controllers and notifiers.
- `NeatFormFieldMapExtension` for querying and validating field maps.
- `NeatErrorResolver` for decoupled localization.
