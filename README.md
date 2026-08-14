# neat_form 📋

> **[Tiếng Việt](#tiếng-việt) | [English](#english)**

---

<a name="tiếng-việt"></a>
## 🇻🇳 Tiếng Việt

**`neat_form`** là một thư viện quản lý trạng thái form và validation gọn nhẹ, mạnh mẽ, type-safe (an toàn kiểu dữ liệu) dành cho **Dart & Flutter**. Thư viện được thiết kế theo tư duy **State-driven**, **Immutable**, và **Zero UI Coupling** (hoàn toàn không phụ thuộc vào `BuildContext` hay widget UI cụ thể).

---

### ✨ Tính năng nổi bật

- 🚀 **Zero UI Coupling:** Core logic thuần Pure Dart, không phụ thuộc `BuildContext`, dễ dàng viết Unit Test mà không cần render Widget.
- 🔒 **Type-Safe & Immutable:** Kiểm tra kiểu dữ liệu tĩnh lúc compile-time với `NeatFieldState<T>` và `NeatValidator<T>`.
- 🌐 **Tách biệt Localization (Đa ngôn ngữ):** Lỗi validation trả về `code` dạng machine-readable và `params`, tầng UI tự do map sang file dịch (`l10n`/`i18n`) theo ý muốn.
- ⚡ **Tương thích mọi State Management:** Hoạt động mượt mà với **Riverpod**, **Bloc/Cubit**, **ValueNotifier**, **MobX**, **GetX**, v.v.
- 🛠️ **Bộ Validators phong phú:** `required`, `email`, `minLength`, `maxLength`, `lengthRange`, `minValue`, `maxValue`, `match` (kiểm tra khớp mật khẩu), `pattern` (Regex), `noSpecialChars`, `alphanumericOnly`, `noSpaces`, `blacklist` và hàm gộp `combine`.
- ⏱️ **Hỗ trợ Async & Sync:** Hỗ trợ validation bất đồng bộ (Async Validator) như kiểm tra trùng email/tên tài khoản từ server với cờ `isValidating`.
- 🧙 **Hỗ trợ Multi-step Form:** Cho phép validate từng cụm trường cho các form nhiều bước (Wizard form).

---

### 📦 Cài đặt

Thêm `neat_form` vào file `pubspec.yaml`:

```yaml
dependencies:
  neat_form: ^1.0.0
```

---

### 🚀 Hướng dẫn sử dụng nhanh

#### 1. Định nghĩa Form State & Controller (ví dụ với Riverpod)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neat_form/neat_form.dart';

// 1. Định nghĩa các key của form
enum LoginFormKey { email, password }

// 2. Định nghĩa State chứa Map các trường
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

// 3. Quản lý logic với NeatFormMixin
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

  // Khai báo tập luật validate
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

  // Cập nhật giá trị và validate real-time
  void onEmailChanged(String val) {
    setAndValidateField(LoginFormKey.email, val);
  }

  void onPasswordChanged(String val) {
    setAndValidateField(LoginFormKey.password, val);
  }

  // Validate toàn bộ form khi submit
  void submit() {
    if (!validateForm()) {
      print('Form không hợp lệ!');
      return;
    }
    print('Submit form thành công: ${fields.toValuesMap()}');
  }
}
```

#### 2. Hiển thị trên Giao diện (Flutter UI)

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
        return 'Vui lòng nhập trường này';
      case NeatValidators.codeEmail:
        return 'Email không hợp lệ';
      default:
        return error.message ?? 'Lỗi không hợp lệ';
    }
  }
}
```

#### 3. Xác thực Bất đồng bộ (Async Validation)

```dart
Future<void> checkUsernameAvailability(String username) async {
  await validateFieldAsync(
    LoginFormKey.email,
    (value) async {
      final isAvailable = await apiService.checkEmail(value);
      if (!isAvailable) {
        return const NeatValidationError(
          'email_taken',
          message: 'Email này đã được sử dụng',
        );
      }
      return null;
    },
  );
}
```

---

<br />
<hr />
<br />

<a name="english"></a>
## 🇬🇧 English

**`neat_form`** is a lightweight, robust, and type-safe form state management and validation library for **Dart & Flutter**. It is designed around **State-driven**, **Immutable**, and **Zero UI Coupling** principles (completely independent from `BuildContext` and specific UI widgets).

---

### ✨ Key Features

- 🚀 **Zero UI Coupling:** Pure Dart core without `BuildContext` dependencies — easily unit test form logic without rendering widgets.
- 🔒 **Type-Safe & Immutable:** Full compile-time static type safety with `NeatFieldState<T>` and `NeatValidator<T>`.
- 🌐 **Clean Localization Architecture:** Validation errors produce machine-readable `code` and `params`, allowing the UI layer to map them to your localization solution (`l10n`/`i18n`) seamlessly.
- ⚡ **State-Manager Agnostic:** Works flawlessly with **Riverpod**, **Bloc/Cubit**, **ValueNotifier**, **MobX**, **GetX**, and more.
- 🛠️ **Rich Built-in Validators:** `required`, `email`, `minLength`, `maxLength`, `lengthRange`, `minValue`, `maxValue`, `match` (e.g. confirm password), `pattern` (Regex), `noSpecialChars`, `alphanumericOnly`, `noSpaces`, `blacklist`, and `combine`.
- ⏱️ **Sync & Async Validation:** First-class support for asynchronous server-side validations (e.g. check username availability) with the `isValidating` flag.
- 🧙 **Multi-step Form Support:** Validate specific subsets of fields for multi-step wizard flows.

---

### 📦 Installation

Add `neat_form` to your `pubspec.yaml`:

```yaml
dependencies:
  neat_form: ^1.0.0
```

---

### 🚀 Quick Start

#### 1. Define Form State & Notifier (Riverpod Example)

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

#### 2. Render in Flutter UI

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

---

## 📝 License

MIT License. See [LICENSE](LICENSE) for details.
