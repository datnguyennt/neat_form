# neat_form 📋

A clean, lightweight, robust, and type-safe (100% `Object?`) form state management and validation library for **Flutter & Dart**.

[![pub package](https://img.shields.io/badge/pub-v1.0.0-blue.svg)](https://pub.dev/packages/neat_form)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tests: 72 Passed](https://img.shields.io/badge/tests-72%20passed-brightgreen.svg)](https://github.com/datnguyennt/neat_form)
[![Zero Dependencies](https://img.shields.io/badge/dependencies-0%20external-success.svg)](https://pub.dev)

> **[Tiếng Việt](README.md) | [English](README_EN.md)**

---

## 🇬🇧 Overview

**`neat_form`** is built around **Headless Architecture (Zero UI Coupling)**, **State-driven**, and **Immutable** design principles. It eliminates the boilerplate and complexity of form validation in Flutter, working out-of-the-box as a standalone solution or integrating seamlessly with any state manager (Riverpod, BLoC, Cubit, Signals, MobX, etc.).

---

### 🌐 Supported Platforms

`neat_form` runs flawlessly on all Flutter-supported platforms:

| Platform | Supported | Notes |
| :--- | :---: | :--- |
| **Android** | ✅ | All Android API versions |
| **iOS** | ✅ | All iOS versions |
| **Web** | ✅ | CanvasKit & HTML renderers |
| **macOS** | ✅ | Desktop App |
| **Windows** | ✅ | Desktop App |
| **Linux** | ✅ | Desktop App |

---

### ⚙️ System Requirements

- **Flutter SDK:** `>= 3.0.0`
- **Dart SDK:** `>= 3.0.0 < 4.0.0`
- **Zero Third-party Dependencies:** Only depends on Flutter SDK & `meta`. Guarantees **100% No Dependency Conflicts** with any existing project.

---

### ✨ Key Features

- 🚀 **Zero UI Coupling (Headless Form):** Pure logic layer — complete freedom to bind to any UI widgets (`TextField`, custom inputs, design systems).
- 🎯 **Native Flutter Integration:** `NeatFormController` extends `ChangeNotifier` / `Listenable` for direct reactive usage with `ListenableBuilder` or `AnimatedBuilder`.
- 🔒 **Strict Type Safety (100% `Object?` - No `dynamic`):** Full compile-time static type checks with `NeatFieldState<T>` and `NeatValidator<T>`.
- 🌐 **Decoupled Localization & Param Interpolation:** Validation errors produce machine-readable codes and params; `NeatErrorResolver` interpolates template placeholders like `{minLength}` and `{maxValue}`.
- ⏱️ **Race Condition Protection in Async Validations:** Token invalidation mechanism ensures slow in-flight async requests never overwrite newer user input.
- 🔄 **Form Submission Lifecycle:** Built-in 4-state lifecycle (`idle`, `submitting`, `success`, `failure`).
- 🛠️ **25+ Built-in Validators:** Strings, numbers, regex, Luhn algorithm credit card, dates, booleans, and collections.

---

### 📦 Installation

Add `neat_form` to your `pubspec.yaml`:

```yaml
dependencies:
  neat_form: ^1.1.0-preview.1
```

Or run:
```bash
flutter pub add neat_form
```

---

### 🚀 Quick Start

#### Approach 1: Flutter Native with `ListenableBuilder` (Recommended)

```dart
import 'package:flutter/material.dart';
import 'package:neat_form/neat_form.dart';

enum LoginFormKey { email, password }

class LoginFormPage extends StatefulWidget {
  const LoginFormPage({super.key});

  @override
  State<LoginFormPage> createState() => _LoginFormPageState();
}

class _LoginFormPageState extends State<LoginFormPage> {
  late final NeatFormController<LoginFormKey> _form;

  @override
  void initState() {
    super.initState();
    _form = NeatFormController<LoginFormKey>(
      initialFields: {
        LoginFormKey.email: const NeatFieldState<String>(value: ''),
        LoginFormKey.password: const NeatFieldState<String>(value: ''),
      },
      validators: {
        LoginFormKey.email: NeatValidators.combine([
          NeatValidators.required(message: 'Email is required'),
          NeatValidators.email(message: 'Invalid email format'),
        ]),
        LoginFormKey.password: NeatValidators.combine([
          NeatValidators.required(message: 'Password is required'),
          NeatValidators.minLength(8, message: 'Must be at least {minLength} characters'),
          NeatValidators.passwordStrength(message: 'Must include uppercase, lowercase, digit & symbol'),
        ]),
      },
    );
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _form,
      builder: (context, _) {
        final emailField = _form.getField<String>(LoginFormKey.email);
        final passwordField = _form.getField<String>(LoginFormKey.password);

        return Column(
          children: [
            TextField(
              onChanged: (val) => _form.setField(LoginFormKey.email, val),
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: emailField.isErrorVisible ? emailField.error?.message : null,
              ),
            ),
            TextField(
              obscureText: true,
              onChanged: (val) => _form.setField(LoginFormKey.password, val),
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: passwordField.isErrorVisible ? passwordField.error?.message : null,
              ),
            ),
            ElevatedButton(
              onPressed: _form.submissionStatus.isSubmitting
                  ? null
                  : () async {
                      await _form.submitForm(
                        onSubmit: (values) async {
                          // Submit to backend API
                          print('Submitted values: $values');
                        },
                      );
                    },
              child: _form.submissionStatus.isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
          ],
        );
      },
    );
  }
}
```

---

#### Approach 2: With Riverpod (`NeatFormMixin`)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neat_form/neat_form.dart';

enum SignupKey { email, password, confirmPassword }

class SignupState {
  final Map<SignupKey, NeatFieldState<Object?>> fields;

  const SignupState({
    this.fields = const {
      SignupKey.email: NeatFieldState<String>(value: ''),
      SignupKey.password: NeatFieldState<String>(value: ''),
      SignupKey.confirmPassword: NeatFieldState<String>(value: ''),
    },
  });

  bool get isValid => fields.areAllFieldsValid;
}

class SignupNotifier extends Notifier<SignupState> with NeatFormMixin<SignupKey> {
  @override
  SignupState build() => const SignupState();

  @override
  Map<SignupKey, NeatFieldState<Object?>> get fields => state.fields;

  @override
  void updateStateWithFields(Map<SignupKey, NeatFieldState<Object?>> newFields) {
    state = SignupState(fields: newFields);
  }

  @override
  Map<SignupKey, NeatValidator<Object?>> get validators => {
        SignupKey.email: NeatValidators.combine([
          NeatValidators.required(),
          NeatValidators.email(),
        ]),
        SignupKey.password: NeatValidators.combine([
          NeatValidators.required(),
          NeatValidators.minLength(8),
        ]),
        SignupKey.confirmPassword: NeatValidators.match(
          () => getField<String>(SignupKey.password).value,
          message: 'Passwords do not match',
        ),
      };

  void onEmailChanged(String val) => setAndValidateField(SignupKey.email, val);
  void onPasswordChanged(String val) => setAndValidateField(SignupKey.password, val);
}
```

---

#### Approach 3: With BLoC / Cubit

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neat_form/neat_form.dart';

enum ProfileKey { name, age }

class ProfileState {
  final Map<ProfileKey, NeatFieldState<Object?>> fields;
  final NeatSubmissionStatus status;

  const ProfileState({
    this.fields = const {
      ProfileKey.name: NeatFieldState<String>(value: ''),
      ProfileKey.age: NeatFieldState<int?>(value: null),
    },
    this.status = NeatSubmissionStatus.idle,
  });
}

class ProfileCubit extends Cubit<ProfileState> with NeatFormMixin<ProfileKey> {
  ProfileCubit() : super(const ProfileState());

  @override
  Map<ProfileKey, NeatFieldState<Object?>> get fields => state.fields;

  @override
  NeatSubmissionStatus get submissionStatus => state.status;

  @override
  void updateStateWithFields(Map<ProfileKey, NeatFieldState<Object?>> newFields) {
    emit(ProfileState(fields: newFields, status: state.status));
  }

  @override
  void updateSubmissionStatus(NeatSubmissionStatus status) {
    emit(ProfileState(fields: state.fields, status: status));
  }

  @override
  Map<ProfileKey, NeatValidator<Object?>> get validators => {
        ProfileKey.name: NeatValidators.required(message: 'Name is required'),
        ProfileKey.age: NeatValidators.combine([
          NeatValidators.required(),
          NeatValidators.minValue(18, message: 'Must be 18+'),
        ]),
      };

  void onNameChanged(String val) => setAndValidateField(ProfileKey.name, val);
  void onAgeChanged(int? val) => setAndValidateField(ProfileKey.age, val);
}
```

---

### 📋 Built-in Validators Cheat Sheet

| Category | Validator | Description |
| :--- | :--- | :--- |
| **Required & Strings** | `required()` | Field must not be null or empty |
| | `notBlank()` | String must not be purely whitespace |
| | `exactLength(n)` | String must have exact length of $n$ chars |
| | `minLength(n)` | Minimum string length |
| | `maxLength(n)` | Maximum string length |
| | `lengthRange(min, max)` | Length within range $[min, max]$ |
| | `startsWith(prefix)` | String starts with specified prefix |
| | `endsWith(suffix)` | String ends with specified suffix |
| | `contains(sub)` / `notContains(sub)` | Substring inclusion / exclusion |
| | `latinOnly()` | Unaccented Latin characters and spaces only |
| | `noEmoji()` | Disallows Emoji characters |
| **Format & Security** | `email()` | Standard international email format |
| | `phone()` | Phone number (8-15 digits, optional `+`) |
| | `passwordStrength()` | Enforces uppercase, lowercase, digits, symbols |
| | `creditCard()` | Credit card validation using Luhn Algorithm |
| | `url()` | HTTP/HTTPS web address format |
| | `numeric()` | Integer or decimal string |
| | `alphanumericOnly()` | Letters and digits only |
| | `noSpecialChars()` | No special symbol characters |
| | `noSpaces()` / `noLeadingTrailingSpaces()` | No spaces / no outer whitespace |
| | `blacklist(words)` | Disallows forbidden keywords |
| | `noHtml()` | Disallows HTML / script tags (anti-XSS) |
| **Numeric** | `minValue(n)` / `maxValue(n)` | Minimum / maximum numeric value |
| | `positive()` / `negative()` | Strictly positive ($>0$) or negative ($<0$) |
| | `multipleOf(step)` | Number must be divisible by step |
| | `decimalPrecision(maxDec)` | Maximum decimal places allowed |
| **DateTime** | `pastDate()` | Date must be in the past |
| | `futureDate()` | Date must be in the future |
| | `dateRange(min, max)` | Date within range $[min, max]$ |
| **Consent & Booleans**| `mustBeTrue()` | Must be true (e.g. Terms acceptance) |
| | `mustBeFalse()` | Must be false |
| **Collections** | `minItems(n)` / `maxItems(n)` | Minimum / maximum number of items |
| | `uniqueItems()` | Disallows duplicate items in list |
| **Logic & Combinators** | `match(targetGetter)` | Matches another field value (confirm password) |
| | `when(condition, validator)` | Conditional validation rule (`requiredIf`) |
| | `combine([v1, v2, ...])` | Combines multiple validators into one |
| | `custom(predicate)` | Creates quick custom predicate validator |

---

### 🌐 Localization & Error Resolver

`neat_form` decouples UI presentation from validation logic:

```dart
final resolver = NeatErrorResolver<BuildContext>();

// Register handler
resolver.register(
  NeatValidators.codeMinLength,
  (context, params, fieldName) {
    return '$fieldName must be at least ${params["minLength"]} characters';
  },
);

// Resolve in UI
final errorText = resolver.resolve(context, fieldState.error!, fieldName: 'Password');
```

---

### ⚠️ Limitations & FAQ

#### 1. Does neat_form provide pre-built UI widgets like `NeatTextField`?
> **No.** `neat_form` follows the **Headless Form** philosophy. It manages state and logic, giving you 100% freedom to use standard `TextField`, `TextFormField`, or your team's custom UI design system.

#### 2. How do I validate a Multi-step / Wizard Form?
> Simply pass the subset of keys for the active step:
> ```dart
> final isStep1Valid = form.validateForm([StepKey.email, StepKey.phone]);
> ```

#### 3. How does async validation handle fast typing?
> `neat_form` includes built-in **Race Condition Tokens** so that obsolete in-flight requests are automatically discarded. Combine it with a simple `Timer` debounce as demonstrated in `example/lib/main.dart`.

---

### 📱 Flutter Showcase App

A complete multi-platform demo application is available inside the `example/` directory.

Run the example app:
```bash
cd example
flutter run -d chrome # or -d ios, -d android, -d macos
```

---

## 📝 License

Released under the [MIT License](LICENSE).
