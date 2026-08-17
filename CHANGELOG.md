# 1.3.0

- **Official Flutter DevTools Extension (`NeatForm` Tab):**
  - Bundled Flutter DevTools Extension package automatically served inside Flutter DevTools when running debug apps.
  - **Form Explorer (Left Panel):** Real-time discovery and searchable hierarchy for active `NeatFormController` & `NeatFormArrayController` instances with status indicators (Valid, Error, Touched, Submitting).
  - **Field Inspector & Live Value Mutator (Center Panel):** Deep inspection for each field state (value, initial value, validation errors, error codes, touch status) with ability to override and inject values live into the running app.
  - **Dynamic Form Array Multi-Level Inspector:** Expandable array item tree and sub-form field mutation.
  - **Smart Autofill & Boundary Test Generator:** 1-click generation of valid test values (`mode: 'valid'`) or edge-case / invalid boundary inputs (`mode: 'boundary'`) for rapid UI validation testing.
  - **JSON State Import & Bug Reproduction:** 1-click modal to paste JSON state snapshots and bulk-update form conditions live.
  - **Live Event Stream Timeline (Right Panel):** Real-time telemetry feed recording all form events (`neat_form:event`) with exact timestamps and formatted payload inspection.
  - **Host Bridge & VM Service Extensions:** Registered 7 VM Service extensions (`getForms`, `getFormDetails`, `setFieldValue`, `validateForm`, `resetForm`, `autofillMock`, `importState`) using `WeakReference` memory management (zero leaks, tree-shaken in release mode).
  - Added `valueOf<T>(key)` helper on `NeatFormController` and `isEmpty`/`isNotEmpty` getters on `NeatFormArrayController`.
  - Expanded unit test suite to **215 tests** with **98.68% overall code coverage** and **0 static analysis warnings**.

# 1.2.7

- **NeatForm UI Builders Suite (Scoped & Fine-Grained Reactivity):**
  - Added `NeatFormScope<K>` and `NeatFormArrayScope<K>` inherited widgets for zero-prop dependency injection across the widget tree.
  - Added `NeatFieldBuilder<K, T>` for fine-grained scoped reactivity, eliminating unnecessary re-renders when other fields mutate.
  - Added `NeatFormBuilder<K>` for observing form-level properties (`isValid`, `submissionStatus`, `errorMessage`) with custom `buildWhen` predicates.
  - Added `NeatFormArrayBuilder<K>` for dynamic array state observing and seamless CRUD actions.
  - Added `NeatSubmitButton<K>` with automatic loading spinner, validation disabling, and controller binding.
  - Added `field<T>` and `submissionStatus` convenient aliases.
  - Expanded unit and widget test suite to **205 tests** with **98.53% overall coverage** and **96.21% coverage** on UI builders.

# 1.2.6

- **Open Source Contribution Guidelines & Templates:**
  - Added `CONTRIBUTING.md` guide with detailed instructions for bug reporting, feature requests, and Pull Request workflows.
  - Added GitHub Issue templates for Bug Reports and Feature Requests.
  - Added GitHub Pull Request template with testing checklists and contribution criteria.
  - Fixed example app payment form fields data loss on rebuilds by adding `initialValue` properties.

# 1.2.5

- **Comprehensive Validator Suite Expansion & Edge Case Hardening:**
  - Added `NeatValidators.dateString` supporting strict calendar checks (valid month 1-12, days 1-31, leap years, days per month) with `minAge`, `maxAge`, `minYear`, `maxYear`, `mustBePast`, and `mustBeFuture` options.
  - Upgraded core numeric validators (`minValue`, `maxValue`, `positive`, `negative`, `multipleOf`) to support auto-coercion of numeric string inputs from text fields.
  - Added new numeric range & type validators: `valueRange` (between), `nonNegative` (>= 0), `nonPositive` (<= 0), and `integerOnly`.
  - Added `timeString` validator for standard 24-hour time strings (`HH:mm` or `HH:mm:ss`).
  - Added choice / collection validators: `oneOf` and `noneOf`.
  - Added format & network validators: `creditCardExpiry` (MM/YY or MM/YYYY), `ipv4`, `ipv6`, `ipAddress`, `uuid`, `hexColor`, and `jsonString`.
  - Updated showcase checkout example with real-time date of birth calendar validation.
  - Expanded unit test suite to **182 tests** achieving **98.72% code coverage** with 0 lints.

# 1.2.4

- **Dynamic Form Array Edge-Case Hardening & Async Validation:**
  - Added auto-template population on `addItem` & `insertItem` from `itemValidators.keys` to prevent `ArgumentError` when mutating uninitialized fields.
  - Added union key validation in `validateArray` so sub-forms missing initial keys are properly validated against `itemValidators`.
  - Added `validateArrayFieldAsync<T>` supporting sub-form async validation with per-item sequence tokens to eliminate race conditions.
  - Added `removeWhere`, `clearItems`, `setItems`, and `reorderItem` (compatible with `ReorderableListView`) across `NeatFormArrayController` and all 4 Notifier/Cubit mixins.
  - Added `onError` callback in `submitForm` returning both array-level error and structured per-item errors (`List<Map<K, NeatValidationError>>`).
  - Enhanced `NeatArrayValidators.uniqueBy` with `caseSensitive: false`, `trim: true`, and `ignoreEmpty: true`.
  - Added `isTouched` getters on both `NeatFormState` and `NeatFormArrayState`.
  - Expanded test suite to **166 tests** with **98.85% code coverage**.

# 1.2.3

- **Dynamic Form Array Suite (`NeatFormArray`):**
  - Added zero-dependency `NeatFormArrayItem<K>` with auto-generated collision-free stable `id` for reliable Flutter widget `ValueKey(item.id)` bindings without focus hopping.
  - Added immutable `NeatFormArrayState<K>` with type-safe operators, copyWith, `isValid`, `isDirty`, `values` extraction, and deep equality.
  - Added `NeatArrayValidators` suite: `minItems`, `maxItems`, `lengthRange`, `uniqueBy` (for duplicate passport/field detection), and `custom`.
  - Added `NeatFormArrayController<K>` with full CRUD (`addItem`, `insertItem`, `removeItemAt`, `removeItemById`, `moveItem`, `setArrayField`, `setAndValidateArrayField`, `validateArray`, `submitForm`, `resetArray`, `clearErrors`).
  - Added state management mixins: `NeatFormArrayNotifierMixin` / `NeatNestedFormArrayNotifierMixin` (Riverpod) and `NeatFormArrayCubitMixin` / `NeatNestedFormArrayCubitMixin` (BLoC/Cubit).
  - Added `factory NeatFormController.fromValues` constructor and `controller.state` / `controller.isValid` getters.
  - Added interactive full demo screen `DynamicCheckoutShowcaseScreen` combining Dynamic Form Array, Masking Formatters, and live JSON telemetry.
  - Redesigned all vector SVG architecture diagrams with solid white card backgrounds for flawless contrast on both Dark Mode and Light Mode on pub.dev and GitHub.
  - Expanded test suite to **162 tests** with **98.93% code coverage**.

# 1.2.2

- **Comprehensive Test Suite & Reliability Hardening:**
  - Expanded test suite to **134 exhaustive tests** achieving **>98.8% test coverage** across all core modules.
  - Tested BLoC/Cubit mixins (`NeatFormCubitMixin`, `NeatNestedFormCubitMixin`) and Riverpod mixins across full CRUD lifecycles.
  - Tested edge cases for `passwordStrength`, `creditCard` (Luhn algorithm), deep map equality, custom pattern matchers, and exception recovery.

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
