# neat_form 📋

> **[Tiếng Việt](#tiếng-việt) | [English](#english)**

---

<a name="tiếng-việt"></a>
## 🇻🇳 Tiếng Việt

**`neat_form`** là một thư viện quản lý trạng thái form và validation gọn nhẹ, mạnh mẽ, type-safe (an toàn kiểu dữ liệu) dành cho **Flutter & Dart**. Thư viện được thiết kế theo tư duy **State-driven**, **Immutable**, và **Zero UI Coupling** (hoàn toàn không phụ thuộc vào `BuildContext` hay widget UI cụ thể).

---

### ✨ Tính năng nổi bật

- 🚀 **Zero UI Coupling:** Core logic thuần Dart, dễ dàng viết Unit Test mà không cần render Widget.
- 🎯 **Tương thích hoàn hảo với Flutter:** `NeatFormController` kế thừa `ChangeNotifier`/`Listenable`, dùng trực tiếp với `ListenableBuilder` hoặc `AnimatedBuilder`.
- 🔒 **Type-Safe & Immutable (100% `Object?` - No `dynamic`):** Kiểm tra kiểu dữ liệu tĩnh lúc compile-time với `NeatFieldState<T>` và `NeatValidator<T>`.
- 🌐 **Localization & Parameter Interpolation:** Lỗi validation trả về `code` và `params`, `NeatErrorResolver` tự động thay thế template `{minLength}`.
- ⚡ **Tương thích mọi State Management:** Hoạt động mượt mà với **Riverpod**, **Bloc/Cubit**, **ValueNotifier**, hoặc dùng độc lập với `NeatFormController`.
- 🛠️ **Bộ Validators toàn diện (25+ built-in rules):**
  - **Chuỗi:** `required()`, `notBlank()`, `exactLength()`, `minLength()`, `maxLength()`, `lengthRange()`, `startsWith()`, `endsWith()`, `contains()`, `notContains()`, `latinOnly()`, `noEmoji()`.
  - **Định dạng & Bảo mật:** `email()`, `phone()`, `passwordStrength()`, `creditCard()` (Luhn Algorithm), `url()`, `numeric()`, `alphanumericOnly()`, `noSpecialChars()`, `noSpaces()`, `blacklist()`, `noHtml()` (anti-XSS).
  - **Số học:** `minValue()`, `maxValue()`, `positive()`, `negative()`, `multipleOf()`, `decimalPrecision()`.
  - **Ngày tháng:** `pastDate()`, `futureDate()`, `dateRange()`.
  - **Consent & Boolean:** `mustBeTrue()`, `mustBeFalse()`.
  - **Mảng & Danh sách:** `minItems()`, `maxItems()`, `uniqueItems()`.
  - **Nâng cao & Ghép nối:** `match()` (khớp mật khẩu), `when()` (có điều kiện), `combine()`, `custom()`.
- ⏱️ **Hỗ trợ Async & Race Protection:** Validation bất đồng bộ tự động hủy bỏ kết quả cũ khi có request mới hoặc khi form reset.
- 🔄 **Submission Lifecycle:** Tích hợp sẵn `submissionStatus` (`idle`, `submitting`, `success`, `failure`) trong `submitForm()`.

---

### 📦 Cài đặt

Thêm `neat_form` vào file `pubspec.yaml`:

```yaml
dependencies:
  neat_form: ^1.0.0
```

---

### 🚀 Hướng dẫn sử dụng nhanh

#### Cách 1: Sử dụng với Flutter `ListenableBuilder` (Không cần State Management ngoài)

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
          NeatValidators.required(message: 'Email không được để trống'),
          NeatValidators.email(message: 'Email không hợp lệ'),
        ]),
        LoginFormKey.password: NeatValidators.combine([
          NeatValidators.required(message: 'Mật khẩu không được để trống'),
          NeatValidators.minLength(8, message: 'Tối thiểu {minLength} ký tự'),
          NeatValidators.passwordStrength(message: 'Cần ít nhất 1 chữ hoa, 1 số, 1 ký tự đặc biệt'),
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
                labelText: 'Mật khẩu',
                errorText: passwordField.isErrorVisible ? passwordField.error?.message : null,
              ),
            ),
            ElevatedButton(
              onPressed: _form.submissionStatus.isSubmitting
                  ? null
                  : () async {
                      await _form.submitForm(
                        onSubmit: (values) async {
                          print('Submit thành công: $values');
                        },
                      );
                    },
              child: _form.submissionStatus.isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Đăng nhập'),
            ),
          ],
        );
      },
    );
  }
}
```

---

#### Cách 2: Quản lý với Riverpod (`NeatFormMixin`)

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
          message: 'Mật khẩu xác nhận không khớp',
        ),
      };

  void onEmailChanged(String val) => setAndValidateField(SignupKey.email, val);
  void onPasswordChanged(String val) => setAndValidateField(SignupKey.password, val);
}
```

---

#### Cách 3: Quản lý với BLoC / Cubit

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
        ProfileKey.name: NeatValidators.required(message: 'Tên không được để trống'),
        ProfileKey.age: NeatValidators.combine([
          NeatValidators.required(),
          NeatValidators.minValue(18, message: 'Phải từ 18 tuổi trở lên'),
        ]),
      };

  void onNameChanged(String val) => setAndValidateField(ProfileKey.name, val);
  void onAgeChanged(int? val) => setAndValidateField(ProfileKey.age, val);
}
```

---

### 📱 Ứng dụng Flutter Mẫu (Showcase App)

Ứng dụng mẫu hoàn chỉnh đa màn hình nằm tại `example/lib/main.dart` bao gồm:
1. **Tab 1: Auth & Registration**: Validation họ tên (latinOnly, noSpecialChars), email, username (async kiểm tra trùng lặp với loading & debounce), password strength, match confirm password, mustBeTrue điều khoản.
2. **Tab 2: Fintech & Payment**: Thẻ tín dụng (Luhn algorithm), hạn thẻ (MM/YY), CVV 3 số, số tiền thanh toán (positive, decimalPrecision).
3. **Tab 3: Booking & E-Commerce**: Đặt phòng ngày nhận/trả (Cross-field `checkout > checkin`), số khách, xuất hóa đơn VAT (`when` checkbox được chọn), tiện ích yêu cầu (`minItems`, `uniqueItems`).

Để chạy ứng dụng mẫu:
```bash
flutter run example/lib/main.dart
```

---

<br />
<hr />
<br />

<a name="english"></a>
## 🇬🇧 English

**`neat_form`** is a clean, lightweight, robust, and type-safe form state management and validation library for **Flutter & Dart**. Built around **State-driven**, **Immutable**, and **Zero UI Coupling** principles.

---

### ✨ Key Features

- 🚀 **Zero UI Coupling:** Pure core logic — easily unit test form business logic without rendering widgets.
- 🎯 **Native Flutter Integration:** `NeatFormController` extends `ChangeNotifier`/`Listenable` for direct usage with `ListenableBuilder` or `AnimatedBuilder`.
- 🔒 **Type-Safe & Immutable (100% `Object?` - No `dynamic`):** Full compile-time static type safety with `NeatFieldState<T>` and `NeatValidator<T>`.
- 🌐 **Localization & Parameter Interpolation:** Produces machine-readable error codes and params; `NeatErrorResolver` automatically interpolates placeholders like `{minLength}`.
- ⚡ **State-Manager Agnostic:** Works seamlessly with **Riverpod**, **Bloc/Cubit**, **ValueNotifier**, or standalone with `NeatFormController`.
- 🛠️ **25+ Built-in Validators:** `required()`, `notBlank()`, `exactLength()`, `email()`, `phone()`, `minLength()`, `maxLength()`, `lengthRange()`, `startsWith()`, `endsWith()`, `contains()`, `notContains()`, `latinOnly()`, `noEmoji()`, `passwordStrength()`, `creditCard()`, `minValue()`, `maxValue()`, `positive()`, `negative()`, `multipleOf()`, `decimalPrecision()`, `pastDate()`, `futureDate()`, `dateRange()`, `mustBeTrue()`, `mustBeFalse()`, `minItems()`, `maxItems()`, `uniqueItems()`, `noHtml()`, `match()`, `when()`, `combine()`, and `custom()`.
- ⏱️ **Sync & Async Validation:** Automatic race-condition protection for async validations and token invalidation on form reset.
- 🔄 **Submission Lifecycle:** Built-in `submissionStatus` (`idle`, `submitting`, `success`, `failure`) inside `submitForm()`.

---

### 📦 Installation

Add `neat_form` to your `pubspec.yaml`:

```yaml
dependencies:
  neat_form: ^0.0.1
```

---

## 📝 License

MIT License. See [LICENSE](LICENSE) for details.
