# neat_form 📋

A clean, lightweight, type-safe form state management and validation library for Dart & Flutter.

[![pub package](https://img.shields.io/badge/pub-v1.0.0-blue.svg)](https://pub.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **[Tiếng Việt](README.md) | [English](README_EN.md)**

---

## ✨ Features

- 🚀 **Zero UI Coupling:** Pure Dart core without `BuildContext` dependencies — easily unit test form logic without rendering widgets.
- 🔒 **Type-Safe & Immutable:** Full compile-time static type safety with `NeatFieldState<T>` and `NeatValidator<T>`.
- 🌐 **Clean Localization Architecture:** Validation errors produce machine-readable `code` and `params`, allowing the UI layer to map them to your localization solution (`l10n`/`i18n`) seamlessly.
- ⚡ **State-Manager Agnostic:** Works flawlessly with **Riverpod**, **Bloc/Cubit**, **ValueNotifier**, **MobX**, **GetX**, and more.
- 🛠️ **Rich Built-in Validators:** `required`, `email`, `minLength`, `maxLength`, `lengthRange`, `minValue`, `maxValue`, `match` (e.g. confirm password), `pattern` (Regex), `noSpecialChars`, `alphanumericOnly`, `noSpaces`, `blacklist`, and `combine`.
- ⏱️ **Sync & Async Validation:** First-class support for asynchronous server-side validations (e.g. check username availability) with the `isValidating` flag.
- 🧙 **Multi-step Form Support:** Validate specific subsets of fields for multi-step wizard flows.

---

## 📦 Installation

Add `neat_form` to your `pubspec.yaml`:

```yaml
dependencies:
  neat_form: ^1.0.0
```

---

## 🚀 Quick Start

### 1. Define Form State & Notifier (Riverpod Example)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neat_form/neat_form.dart';

// 1. Define form keys
enum LoginFormKey { email, password }

// 2. Define state holding the field map
class LoginFormState {
  final Map<LoginFormKey, NeatFieldState<dynamic>> fields;

  const LoginFormState({
    this.fields = const {
      LoginFormKey.email: NeatFieldState<String>(value: ''),
      LoginFormKey.password: NeatFieldState<String>(value: ''),
    },
  });

  bool get isFormValid => fields.isAllFieldsValid;
}

// 3. Manage logic using NeatFormMixin
class LoginNotifier extends Notifier<LoginFormState>
    with NeatFormMixin<LoginFormKey> {
  @override
  LoginFormState build() => const LoginFormState();

  @override
  Map<LoginFormKey, NeatFieldState<dynamic>> get fields => state.fields;

  @override
  void updateStateWithFields(
      Map<LoginFormKey, NeatFieldState<dynamic>> newFields) {
    state = LoginFormState(fields: newFields);
  }

  // Define validation rules
  @override
  Map<LoginFormKey, NeatValidator<dynamic>> get validators => {
        LoginFormKey.email: NeatValidators.combine([
          NeatValidators.required,
          NeatValidators.email(),
        ]),
        LoginFormKey.password: NeatValidators.combine([
          NeatValidators.required,
          NeatValidators.minLength(8),
        ]),
      };

  // Update value and validate in real-time
  void onEmailChanged(String val) {
    setAndValidateField(LoginFormKey.email, val);
  }

  void onPasswordChanged(String val) {
    setAndValidateField(LoginFormKey.password, val);
  }

  // Validate the whole form upon submit
  void submit() {
    if (!validateForm()) {
      print('Form is invalid!');
      return;
    }
    print('Form submitted successfully: ${fields.toValuesMap()}');
  }
}
```

### 2. Render in Flutter UI

```dart
class EmailInputWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailField = ref.watch(
      loginNotifierProvider.select((s) => s.fields.getField<String>(LoginFormKey.email)),
    );

    return TextField(
      onChanged: (val) => ref.read(loginNotifierProvider.notifier).onEmailChanged(val),
      decoration: InputDecoration(
        labelText: 'Email',
        errorText: emailField.isShowError ? _getErrorMessage(emailField.error!) : null,
      ),
    );
  }

  String _getErrorMessage(NeatValidationError error) {
    switch (error.code) {
      case NeatValidators.codeRequired:
        return 'This field is required';
      case NeatValidators.codeEmail:
        return 'Invalid email address';
      default:
        return error.message ?? 'Invalid input';
    }
  }
}
```

### 3. Async Validation

```dart
Future<void> checkUsernameAvailability(String username) async {
  await validateFieldAsync(
    LoginFormKey.email,
    (value) async {
      final isAvailable = await apiService.checkEmail(value);
      if (!isAvailable) {
        return const NeatValidationError(
          'email_taken',
          message: 'This email is already registered',
        );
      }
      return null;
    },
  );
}
```

---

## 📝 License

MIT License. See [LICENSE](LICENSE) for details.
