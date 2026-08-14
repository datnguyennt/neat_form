# neat_form 📋

Một thư viện quản lý trạng thái form và validation gọn nhẹ, mạnh mẽ, type-safe (100% `Object?`) dành cho **Flutter & Dart**.

[![pub package](https://img.shields.io/badge/pub-v1.0.0-blue.svg)](https://pub.dev/packages/neat_form)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tests: 72 Passed](https://img.shields.io/badge/tests-72%20passed-brightgreen.svg)](https://github.com/datnguyennt/neat_form)
[![Zero Dependencies](https://img.shields.io/badge/dependencies-0%20external-success.svg)](https://pub.dev)

> **[Tiếng Việt](#tiếng-việt) | [English](README_EN.md)**

---

<a name="tiếng-việt"></a>
## 🇻🇳 Giới thiệu

**`neat_form`** được thiết kế theo tư duy **Headless (Zero UI Coupling)**, **State-driven**, và **Immutable**. Package giải phóng bạn khỏi sự phức tạp của form validation trong Flutter, hoạt động độc lập hoặc tích hợp liền mạch với mọi thư viện State Management (Riverpod, BLoC, Cubit, Signals, v.v.).

---

### 🌐 Nền tảng hỗ trợ (Supported Platforms)

`neat_form` hoạt động 100% mượt mà trên tất cả các nền tảng được Flutter hỗ trợ:

| Platform | Hỗ trợ | Ghi chú |
| :--- | :---: | :--- |
| **Android** | ✅ | Hỗ trợ mọi phiên bản Android |
| **iOS** | ✅ | Hỗ trợ mọi phiên bản iOS |
| **Web** | ✅ | Tương thích CanvasKit & HTML renderer |
| **macOS** | ✅ | Desktop App |
| **Windows** | ✅ | Desktop App |
| **Linux** | ✅ | Desktop App |

---

### ⚙️ Yêu cầu hệ thống (System Requirements)

- **Flutter SDK:** `>= 3.0.0`
- **Dart SDK:** `>= 3.0.0 < 4.0.0`
- **Zero Third-party Dependencies:** Không phụ thuộc bất kỳ thư viện bên ngoài nào (chỉ dùng Flutter SDK & `meta`), đảm bảo **100% không bao giờ gặp lỗi xung đột phiên bản (No Version Conflicts)**.

---

### ✨ Tính năng nổi bật

- 🚀 **Zero UI Coupling (Headless Form):** Logic form thuần túy, bạn toàn quyền thiết kế giao diện UI theo Design System riêng mà không bị gò bó.
- 🎯 **Native Flutter Integration:** `NeatFormController` kế thừa `ChangeNotifier` / `Listenable`, dùng trực tiếp với `ListenableBuilder` hoặc `AnimatedBuilder` mà không cần cài thêm thư viện ngoài.
- 🔒 **Type-Safe Tuyệt đối (100% `Object?` - No `dynamic`):** Bắt lỗi kiểu tĩnh lúc compile-time, an toàn dữ liệu tuyệt đối.
- 🌐 **Localization Độc lập:** Lỗi trả về `code` và `params`. `NeatErrorResolver` tự động thay thế biến template như `{minLength}`, `{maxValue}` vào câu thông báo.
- ⏱️ **Chống Race Condition trong Async Validation:** Quản lý token tự động hủy kết quả cũ nếu dữ liệu thay đổi trước khi request mạng hoàn tất.
- 🔄 **Submission Lifecycle:** Tự động quản lý 4 trạng thái nộp form (`idle`, `submitting`, `success`, `failure`).
- 🛠️ **25+ Built-in Validators:** Đầy đủ từ chuỗi, số học, regex, thẻ tín dụng Luhn, ngày tháng, consent boolean cho tới mảng/danh sách động.

---

### 📦 Cài đặt

Thêm `neat_form` vào file `pubspec.yaml`:

```yaml
dependencies:
  neat_form: ^1.1.0-preview.1
```

Hoặc chạy lệnh:
```bash
flutter pub add neat_form
```

---

### 🚀 Hướng dẫn sử dụng nhanh

#### Cách 1: Dùng trực tiếp với Flutter `ListenableBuilder` (Khuyên dùng)

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
          NeatValidators.email(message: 'Email không đúng định dạng'),
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
                          // Gọi API Backend
                          print('Dữ liệu form hợp lệ: $values');
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

#### Cách 2: Tích hợp với Riverpod (`NeatFormMixin`)

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

#### Cách 3: Tích hợp với BLoC / Cubit

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

### 📋 Bảng tra cứu Built-in Validators (Cheat Sheet)

| Nhóm | Validator | Mô tả |
| :--- | :--- | :--- |
| **Bắt buộc & Chuỗi** | `required()` | Bắt buộc nhập, không được null/rỗng |
| | `notBlank()` | Không được chỉ chứa toàn khoảng trắng |
| | `exactLength(n)` | Độ dài chuỗi chính xác tuyệt đối $n$ ký tự |
| | `minLength(n)` | Độ dài tối thiểu $n$ ký tự |
| | `maxLength(n)` | Độ dài tối đa $n$ ký tự |
| | `lengthRange(min, max)` | Độ dài nằm trong khoảng $[min, max]$ |
| | `startsWith(prefix)` | Bắt đầu bằng tiền tố |
| | `endsWith(suffix)` | Kết thúc bằng hậu tố |
| | `contains(sub)` / `notContains(sub)` | Chứa hoặc không chứa chuỗi con |
| | `latinOnly()` | Chỉ chứa chữ cái tiếng Anh không dấu |
| | `noEmoji()` | Chặn icon/emoji |
| **Định dạng & Bảo mật** | `email()` | Kiểm tra định dạng email chuẩn |
| | `phone()` | Số điện thoại (8-15 số, hỗ trợ `+`) |
| | `passwordStrength()` | Yêu cầu chữ hoa, thường, số, ký tự đặc biệt |
| | `creditCard()` | Kiểm tra số thẻ tín dụng bằng thuật toán Luhn |
| | `url()` | Địa chỉ website (http, https) |
| | `numeric()` | Chuỗi số nguyên hoặc thập phân |
| | `alphanumericOnly()` | Chỉ gồm chữ cái và chữ số |
| | `noSpecialChars()` | Không chứa ký tự đặc biệt |
| | `noSpaces()` / `noLeadingTrailingSpaces()` | Không có dấu cách / dấu cách ở 2 đầu |
| | `blacklist(words)` | Chặn từ khóa nằm trong danh sách đen |
| | `noHtml()` | Chặn thẻ HTML / script chống XSS |
| **Số học** | `minValue(n)` / `maxValue(n)` | Giá trị số tối thiểu / tối đa |
| | `positive()` / `negative()` | Số dương ($> 0$) hoặc số âm ($< 0$) |
| | `multipleOf(step)` | Bội số chia hết (bước nhảy giá) |
| | `decimalPrecision(maxDec)` | Số lượng chữ số thập phân tối đa |
| **Thời gian & Ngày** | `pastDate()` | Ngày phải ở quá khứ (ngày sinh) |
| | `futureDate()` | Ngày phải ở tương lai (hạn thẻ) |
| | `dateRange(min, max)` | Ngày nằm trong khoảng cho phép |
| **Boolean & Consent**| `mustBeTrue()` | Bắt buộc tick (Điều khoản dịch vụ) |
| | `mustBeFalse()` | Bắt buộc là false |
| **Mảng & Danh sách** | `minItems(n)` / `maxItems(n)` | Số lượng phần tử tối thiểu / tối đa |
| | `uniqueItems()` | Danh sách không có phần tử trùng lặp |
| **Logic & Tổ hợp** | `match(targetGetter)` | Khớp với giá trị trường khác (xác nhận mật khẩu) |
| | `when(condition, validator)` | Validate có điều kiện (`requiredIf`) |
| | `combine([v1, v2, ...])` | Ghép nhiều luật validate lại với nhau |
| | `custom(predicate)` | Tự viết hàm validate tùy biến nhanh |

---

### 🌐 Đa ngôn ngữ (Localization & Error Resolver)

`neat_form` tách biệt hoàn toàn thông điệp hiển thị khỏi logic. Bạn có thể định nghĩa template nội suy tham số:

```dart
final resolver = NeatErrorResolver<BuildContext>();

// Đăng ký bộ dịch theo mã lỗi
resolver.register(
  NeatValidators.codeMinLength,
  (context, params, fieldName) {
    return '$fieldName tối thiểu ${params["minLength"]} ký tự';
  },
);

// Sử dụng tại UI
final errorText = resolver.resolve(context, fieldState.error!, fieldName: 'Mật khẩu');
```

---

### ⚠️ Giới hạn & Câu hỏi thường gặp (Limitations & FAQ)

#### 1. Package có cung cấp sẵn các Widget giao diện (ví dụ `NeatTextField`) không?
> **Không.** `neat_form` tuân thủ nguyên lý **Headless Form**. Thư viện quản lý state và validation thuần túy, giúp bạn tự do 100% sử dụng với `TextField`, `TextFormField`, custom design system, hay bất kỳ thư viện UI nào (shadcn-flutter, flutter_neumorphic, v.v.) mà không bị gò bó style.

#### 2. Làm thế nào để validate Form nhiều bước (Wizard / Multi-step Form)?
> Rất đơn giản! Phương thức `validateForm` cho phép truyền vào danh sách các key của bước hiện tại:
> ```dart
> final isStep1Valid = form.validateForm([StepKey.email, StepKey.phone]);
> ```

#### 3. Asynchronous Validation có bị gián đoạn hay làm chậm giao diện không?
> `neat_form` tích hợp cơ chế **Race Condition Token**. Khi người dùng gõ phím liên tục, các kết quả request cũ sẽ tự động bị hủy bỏ và chỉ kết quả mới nhất được cập nhật. Bạn nên kết hợp thêm `Timer` debounce (như minh họa trong thư mục `example/lib/main.dart`).

---

### 📱 Ứng dụng mẫu (Flutter Showcase App)

Ứng dụng mẫu đa nền tảng (iOS, Android, Web, macOS) nằm trong thư mục `example/`.

Chạy ứng dụng mẫu:
```bash
cd example
flutter run -d chrome # hoặc -d ios, -d android, -d macos
```

---

## 📝 Giấy phép (License)

Phát hành dưới giấy phép [MIT License](LICENSE).
