# neat_form 📋

A clean, lightweight, type-safe form state management and validation library for Flutter & Dart.

[![pub package](https://img.shields.io/badge/pub-v0.0.1-blue.svg)](https://pub.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **[Tiếng Việt](README.md) | [English](README_EN.md)**

---

## ✨ Key Features

- 🚀 **Zero UI Coupling:** Pure core logic — easily unit test form business logic without rendering widgets.
- 🎯 **Native Flutter Integration:** `NeatFormController` extends `ChangeNotifier`/`Listenable` for direct usage with `ListenableBuilder` or `AnimatedBuilder`.
- 🔒 **Type-Safe & Immutable (100% `Object?` - No `dynamic`):** Full compile-time static type safety with `NeatFieldState<T>` and `NeatValidator<T>`.
- 🌐 **Localization & Parameter Interpolation:** Produces machine-readable error codes and params; `NeatErrorResolver` automatically interpolates placeholders like `{minLength}`.
- ⚡ **State-Manager Agnostic:** Works seamlessly with **Riverpod**, **Bloc/Cubit**, **ValueNotifier**, or standalone with `NeatFormController`.
- 🛠️ **25+ Built-in Validators:**
  - **Strings:** `required()`, `notBlank()`, `exactLength()`, `minLength()`, `maxLength()`, `lengthRange()`, `startsWith()`, `endsWith()`, `contains()`, `notContains()`, `latinOnly()`, `noEmoji()`.
  - **Formats & Security:** `email()`, `phone()`, `passwordStrength()`, `creditCard()` (Luhn Algorithm), `url()`, `numeric()`, `alphanumericOnly()`, `noSpecialChars()`, `noSpaces()`, `blacklist()`, `noHtml()` (anti-XSS).
  - **Numeric:** `minValue()`, `maxValue()`, `positive()`, `negative()`, `multipleOf()`, `decimalPrecision()`.
  - **DateTime:** `pastDate()`, `futureDate()`, `dateRange()`.
  - **Consent & Boolean:** `mustBeTrue()`, `mustBeFalse()`.
  - **Collections:** `minItems()`, `maxItems()`, `uniqueItems()`.
  - **Advanced & Combinators:** `match()` (confirm password), `when()` (conditional), `combine()`, `custom()`.
- ⏱️ **Sync & Async Validation:** Automatic race-condition protection for async validations and token invalidation on form reset.
- 🔄 **Submission Lifecycle:** Built-in `submissionStatus` (`idle`, `submitting`, `success`, `failure`) inside `submitForm()`.

---

## 📦 Installation

Add `neat_form` to your `pubspec.yaml`:

```yaml
dependencies:
  neat_form: ^0.0.1
```

---

## 🚀 Quick Start

### Approach A: Flutter `ListenableBuilder` (No external state manager)

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
          NeatValidators.email(message: 'Invalid email address'),
        ]),
        LoginFormKey.password: NeatValidators.combine([
          NeatValidators.required(message: 'Password is required'),
          NeatValidators.minLength(8, message: 'Must be at least {minLength} characters'),
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
                          print('Submitted: $values');
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

### Approach B: With Riverpod (`NeatFormMixin`)

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
}
```

---

### Approach C: With BLoC / Cubit

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

### 📱 Flutter Showcase App

A complete multi-screen demo application is available in `example/lib/main.dart`:
- **Tab 1: Account & Auth Flow**: Full name validation (`latinOnly`, `noSpecialChars`), email, username (async uniqueness check with debounce), password strength, match confirm password, `mustBeTrue` terms consent.
- **Tab 2: Fintech & Credit Card**: Credit card number (Luhn Algorithm), card expiry (MM/YY), CVV, payment amount (`positive`, `decimalPrecision`).
- **Tab 3: Booking & E-Commerce**: Hotel reservation dates (Cross-field `checkout > checkin`), guest count, VAT invoice request (`when` switch is enabled), extra amenities (`minItems`, `uniqueItems`).

Run the showcase application:
```bash
flutter run example/lib/main.dart
```

---

## 📝 License

MIT License. See [LICENSE](LICENSE) for details.
