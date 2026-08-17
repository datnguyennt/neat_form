import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neat_form/neat_form.dart';

void main() {
  runApp(const NeatFormShowcaseApp());
}

class NeatFormShowcaseApp extends StatelessWidget {
  const NeatFormShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'neat_form Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        splashFactory: InkRipple.splashFactory,
        colorSchemeSeed: const Color(0xFF4F46E5),
        brightness: Brightness.light,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
          ),
        ),
      ),
      home: const FormShowcaseHomePage(),
    );
  }
}

class FormShowcaseHomePage extends StatelessWidget {
  const FormShowcaseHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.assignment_turned_in_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'neat_form Showcase',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.person_add_rounded), text: 'Tài khoản & Auth'),
              Tab(icon: Icon(Icons.credit_card_rounded), text: 'Fintech & Thẻ'),
              Tab(icon: Icon(Icons.hotel_rounded), text: 'Booking & E-Com'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AuthRegistrationTab(),
            FintechPaymentTab(),
            BookingCrossFieldTab(),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 1: AUTH & REGISTRATION FORM
// ==========================================

enum AuthFormKey {
  fullName,
  email,
  username,
  password,
  confirmPassword,
  termsAccepted,
}

class AuthRegistrationTab extends StatefulWidget {
  const AuthRegistrationTab({super.key});

  @override
  State<AuthRegistrationTab> createState() => _AuthRegistrationTabState();
}

class _AuthRegistrationTabState extends State<AuthRegistrationTab> {
  late final NeatFormController<AuthFormKey> _form;
  Timer? _usernameDebounce;

  @override
  void initState() {
    super.initState();
    _form = NeatFormController<AuthFormKey>(
      initialFields: {
        AuthFormKey.fullName: const NeatFieldState<String>(value: ''),
        AuthFormKey.email: const NeatFieldState<String>(value: ''),
        AuthFormKey.username: const NeatFieldState<String>(value: ''),
        AuthFormKey.password: const NeatFieldState<String>(value: ''),
        AuthFormKey.confirmPassword: const NeatFieldState<String>(value: ''),
        AuthFormKey.termsAccepted: const NeatFieldState<bool>(value: false),
      },
      validators: {
        AuthFormKey.fullName: NeatValidators.combine([
          NeatValidators.required(message: 'Vui lòng nhập họ và tên'),
          NeatValidators.latinOnly(message: 'Họ tên chỉ được chứa chữ cái không dấu'),
          NeatValidators.noSpecialChars(message: 'Không được chứa ký tự đặc biệt'),
        ]),
        AuthFormKey.email: NeatValidators.combine([
          NeatValidators.required(message: 'Vui lòng nhập email'),
          NeatValidators.email(message: 'Email không đúng định dạng'),
        ]),
        AuthFormKey.username: NeatValidators.combine([
          NeatValidators.required(message: 'Vui lòng nhập tên đăng nhập'),
          NeatValidators.minLength(4, message: 'Tên đăng nhập tối thiểu 4 ký tự'),
          NeatValidators.noSpaces(message: 'Tên đăng nhập không được chứa khoảng trắng'),
        ]),
        AuthFormKey.password: NeatValidators.combine([
          NeatValidators.required(message: 'Vui lòng nhập mật khẩu'),
          NeatValidators.minLength(8, message: 'Mật khẩu tối thiểu 8 ký tự'),
          NeatValidators.passwordStrength(
            message: 'Mật khẩu cần ít nhất 1 chữ hoa, 1 chữ thường, 1 số và 1 ký tự đặc biệt',
          ),
        ]),
        AuthFormKey.confirmPassword: NeatValidators.combine([
          NeatValidators.required(message: 'Vui lòng xác nhận mật khẩu'),
          NeatValidators.match(
            () => _form.getField<String>(AuthFormKey.password).value,
            message: 'Mật khẩu xác nhận không khớp',
          ),
        ]),
        AuthFormKey.termsAccepted: NeatValidators.mustBeTrue(
          message: 'Bạn phải đồng ý với Điều khoản dịch vụ',
        ),
      },
    );
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _form.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String val) {
    _form.setField(AuthFormKey.username, val);
    _usernameDebounce?.cancel();
    if (val.length >= 4) {
      _usernameDebounce = Timer(const Duration(milliseconds: 400), () {
        _form.validateFieldAsync<String>(
          AuthFormKey.username,
          (username) async {
            await Future<void>.delayed(const Duration(milliseconds: 600));
            if (username?.toLowerCase() == 'admin' || username?.toLowerCase() == 'root') {
              return const NeatValidationError(
                'username_taken',
                message: 'Tên đăng nhập này đã có người sử dụng!',
              );
            }
            return null;
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _form,
      builder: (context, _) {
        final name = _form.getField<String>(AuthFormKey.fullName);
        final email = _form.getField<String>(AuthFormKey.email);
        final username = _form.getField<String>(AuthFormKey.username);
        final password = _form.getField<String>(AuthFormKey.password);
        final confirm = _form.getField<String>(AuthFormKey.confirmPassword);
        final terms = _form.getField<bool>(AuthFormKey.termsAccepted);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader('Đăng ký tài khoản & Bảo mật', Icons.lock_outline),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Họ và tên (In trên thẻ/Vé máy bay)',
                hintText: 'NGUYEN VAN A',
                prefixIcon: const Icon(Icons.badge_outlined),
                errorText: name.errorMessage,
              ),
              onChanged: (val) => _form.setField(AuthFormKey.fullName, val),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                errorText: email.errorMessage,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (val) => _form.setField(AuthFormKey.email, val),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Tên đăng nhập (Kiểm tra trùng async)',
                hintText: 'Thử nhập "admin"',
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                suffixIcon: username.isValidating
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                errorText: username.errorMessage,
              ),
              onChanged: _onUsernameChanged,
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mật khẩu bảo mật',
                prefixIcon: const Icon(Icons.key_outlined),
                errorText: password.errorMessage,
              ),
              onChanged: (val) => _form.setField(AuthFormKey.password, val),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Xác nhận mật khẩu',
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                errorText: confirm.errorMessage,
              ),
              onChanged: (val) => _form.setField(AuthFormKey.confirmPassword, val),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tôi đồng ý với Điều khoản dịch vụ & Chính sách bảo mật'),
              value: terms.value,
              subtitle: terms.isErrorVisible
                  ? Text(
                      terms.error?.message ?? '',
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                    )
                  : null,
              onChanged: (val) => _form.setField(AuthFormKey.termsAccepted, val ?? false),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _form.submissionStatus.isSubmitting
                  ? null
                  : () async {
                      final success = await _form.submitForm(
                        onSubmit: (values) async {
                          await Future<void>.delayed(const Duration(seconds: 1));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎉 Đăng ký tài khoản thành công!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      );
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚠️ Vui lòng kiểm tra lại các trường báo lỗi'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
              child: _form.submissionStatus.isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Đăng Ký Ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

// ==========================================
// TAB 2: FINTECH & CREDIT CARD PAYMENT FORM
// ==========================================

enum FintechKey {
  cardNumber,
  cardExpiry,
  cvv,
  amount,
}

class FintechPaymentTab extends StatefulWidget {
  const FintechPaymentTab({super.key});

  @override
  State<FintechPaymentTab> createState() => _FintechPaymentTabState();
}

class _FintechPaymentTabState extends State<FintechPaymentTab> {
  late final NeatFormController<FintechKey> _form;
  final _currencyFormatter = NeatInputFormatters.currency(
    thousandSeparator: '.',
    decimalSeparator: ',',
    suffix: ' ₫',
  );

  @override
  void initState() {
    super.initState();
    _form = NeatFormController<FintechKey>(
      initialFields: {
        FintechKey.cardNumber: const NeatFieldState<String>(value: ''),
        FintechKey.cardExpiry: const NeatFieldState<String>(value: ''),
        FintechKey.cvv: const NeatFieldState<String>(value: ''),
        FintechKey.amount: const NeatFieldState<num?>(value: null),
      },
      validators: {
        FintechKey.cardNumber: NeatValidators.combine([
          NeatValidators.required(message: 'Vui lòng nhập số thẻ'),
          NeatValidators.creditCard(message: 'Số thẻ không hợp lệ theo thuật toán Luhn'),
        ]),
        FintechKey.cardExpiry: NeatValidators.combine([
          NeatValidators.required(message: 'Vui lòng nhập ngày hết hạn (MM/YY)'),
          NeatValidators.pattern(
            RegExp(r'^(0[1-9]|1[0-2])\/?([0-9]{2})$'),
            message: 'Định dạng hạn thẻ phải là MM/YY (ví dụ: 12/28)',
          ),
        ]),
        FintechKey.cvv: NeatValidators.combine([
          NeatValidators.required(message: 'Vui lòng nhập mã CVV'),
          NeatValidators.exactLength(3, message: 'Mã CVV phải có đúng 3 chữ số'),
          NeatValidators.numeric(message: 'CVV chỉ gồm các chữ số'),
        ]),
        FintechKey.amount: NeatValidators.combine([
          NeatValidators.required(message: 'Vui lòng nhập số tiền thanh toán'),
          NeatValidators.positive(message: 'Số tiền giao dịch phải lớn hơn 0'),
          NeatValidators.maxValue(100000000, message: 'Hạn mức giao dịch tối đa 100.000.000đ'),
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
        final card = _form.getField<String>(FintechKey.cardNumber);
        final expiry = _form.getField<String>(FintechKey.cardExpiry);
        final cvv = _form.getField<String>(FintechKey.cvv);
        final amount = _form.getField<num?>(FintechKey.amount);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader('Thanh toán thẻ & Fintech', Icons.payment_rounded),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Số thẻ tín dụng / Ghi nợ (Tự động format & Luhn)',
                hintText: '4532 0151 1283 0366',
                prefixIcon: const Icon(Icons.credit_card_outlined),
                errorText: card.errorMessage,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [NeatInputFormatters.creditCard()],
              onChanged: (val) => _form.setField(
                FintechKey.cardNumber,
                NeatCardFormatter.getCleanCardNumber(val),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Hạn thẻ (MM/YY)',
                      hintText: '12/28',
                      prefixIcon: const Icon(Icons.calendar_month_outlined),
                      errorText: expiry.errorMessage,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      NeatInputFormatters.date(format: NeatDateFormat.mmYy),
                    ],
                    onChanged: (val) => _form.setField(FintechKey.cardExpiry, val),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'CVV / CVC',
                      hintText: '123',
                      prefixIcon: const Icon(Icons.security_rounded),
                      errorText: cvv.errorMessage,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    onChanged: (val) => _form.setField(FintechKey.cvv, val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Số tiền thanh toán (Tự động format tiền tệ)',
                hintText: '500.000 ₫',
                prefixIcon: const Icon(Icons.monetization_on_outlined),
                errorText: amount.errorMessage,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [_currencyFormatter],
              onChanged: (val) => _form.setField(
                FintechKey.amount,
                _currencyFormatter.getNumericValue(val),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _form.submissionStatus.isSubmitting
                  ? null
                  : () async {
                      final success = await _form.submitForm(
                        onSubmit: (values) async {
                          await Future<void>.delayed(const Duration(seconds: 1));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('💳 Thanh toán thành công!'),
                                backgroundColor: Color(0xFF059669),
                              ),
                            );
                          }
                        },
                      );
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚠️ Thông tin thẻ hoặc số tiền không hợp lệ'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
              child: _form.submissionStatus.isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Xác Nhận Thanh Toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

// ==========================================
// TAB 3: BOOKING & CROSS-FIELD FORM
// ==========================================

enum BookingKey {
  checkInDate,
  checkOutDate,
  guestCount,
  promoCode,
  requestVAT,
  companyTaxId,
  tags,
}

class BookingCrossFieldTab extends StatefulWidget {
  const BookingCrossFieldTab({super.key});

  @override
  State<BookingCrossFieldTab> createState() => _BookingCrossFieldTabState();
}

class _BookingCrossFieldTabState extends State<BookingCrossFieldTab> {
  late final NeatFormController<BookingKey> _form;

  @override
  void initState() {
    super.initState();
    _form = NeatFormController<BookingKey>(
      initialFields: {
        BookingKey.checkInDate: const NeatFieldState<DateTime?>(value: null),
        BookingKey.checkOutDate: const NeatFieldState<DateTime?>(value: null),
        BookingKey.guestCount: const NeatFieldState<int>(value: 1),
        BookingKey.promoCode: const NeatFieldState<String>(value: '', isOptional: true),
        BookingKey.requestVAT: const NeatFieldState<bool>(value: false),
        BookingKey.companyTaxId: const NeatFieldState<String>(value: '', isOptional: true),
        BookingKey.tags: const NeatFieldState<List<String>>(value: []),
      },
      validators: {
        BookingKey.checkInDate: NeatValidators.required(message: 'Vui lòng chọn ngày nhận phòng'),
        BookingKey.checkOutDate: NeatValidators.combine([
          NeatValidators.required(message: 'Vui lòng chọn ngày trả phòng'),
          (val) {
            final checkIn = _form.getField<DateTime?>(BookingKey.checkInDate).value;
            final checkOut = val as DateTime?;
            if (checkIn != null && checkOut != null) {
              if (!checkOut.isAfter(checkIn)) {
                return const NeatValidationError(
                  'checkout_before_checkin',
                  message: 'Ngày trả phòng phải sau ngày nhận phòng ít nhất 1 ngày',
                );
              }
            }
            return null;
          },
        ]),
        BookingKey.guestCount: NeatValidators.combine([
          NeatValidators.minValue(1, message: 'Tối thiểu 1 khách'),
          NeatValidators.maxValue(10, message: 'Tối đa 10 khách'),
        ]),
        BookingKey.companyTaxId: NeatValidators.when(
          () => _form.getField<bool>(BookingKey.requestVAT).value,
          NeatValidators.combine([
            NeatValidators.required(message: 'Mã số thuế bắt buộc khi yêu cầu xuất VAT'),
            NeatValidators.exactLength(10, message: 'Mã số thuế doanh nghiệp phải đúng 10 chữ số'),
            NeatValidators.numeric(message: 'Mã số thuế chỉ gồm các chữ số'),
          ]),
        ),
        BookingKey.tags: NeatValidators.combine([
          NeatValidators.minItems(1, message: 'Vui lòng chọn ít nhất 1 tiện ích yêu cầu'),
          NeatValidators.uniqueItems(message: 'Không được chọn trùng lặp tiện ích'),
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
        final checkIn = _form.getField<DateTime?>(BookingKey.checkInDate);
        final checkOut = _form.getField<DateTime?>(BookingKey.checkOutDate);
        final guests = _form.getField<int>(BookingKey.guestCount);
        final vat = _form.getField<bool>(BookingKey.requestVAT);
        final taxId = _form.getField<String>(BookingKey.companyTaxId);
        final tags = _form.getField<List<String>>(BookingKey.tags);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader('Đặt phòng khách sạn & Cross-field', Icons.hotel_class_rounded),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ngày nhận phòng', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      checkIn.value != null ? '${checkIn.value!.day}/${checkIn.value!.month}/${checkIn.value!.year}' : 'Chọn ngày',
                    ),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        _form.setAndValidateField(BookingKey.checkInDate, picked);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ngày trả phòng', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      checkOut.value != null ? '${checkOut.value!.day}/${checkOut.value!.month}/${checkOut.value!.year}' : 'Chọn ngày',
                    ),
                    trailing: const Icon(Icons.event_available_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 2)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        _form.setAndValidateField(BookingKey.checkOutDate, picked);
                      }
                    },
                  ),
                ),
              ],
            ),
            if (checkOut.isErrorVisible)
              Text(
                checkOut.error?.message ?? '',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Số lượng khách',
                prefixIcon: const Icon(Icons.group_outlined),
                errorText: guests.errorMessage,
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: guests.value.toString()),
              onChanged: (val) => _form.setField(BookingKey.guestCount, int.tryParse(val) ?? 1),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Yêu cầu xuất hóa đơn công ty (VAT)'),
              value: vat.value,
              onChanged: (val) {
                _form.setField(BookingKey.requestVAT, val);
                _form.validateField(BookingKey.companyTaxId);
              },
            ),
            if (vat.value) ...[
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Mã số thuế doanh nghiệp (10 số)',
                  prefixIcon: const Icon(Icons.receipt_long_rounded),
                  errorText: taxId.errorMessage,
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) => _form.setField(BookingKey.companyTaxId, val),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Tiện ích yêu cầu thêm (Chọn ít nhất 1):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Bữa sáng Buffet', 'Đưa đón sân bay', 'Phòng view biển', 'Late Check-out'].map((item) {
                final isSelected = tags.value.contains(item);
                return FilterChip(
                  label: Text(item),
                  selected: isSelected,
                  onSelected: (selected) {
                    final current = List<String>.from(tags.value);
                    if (selected) {
                      current.add(item);
                    } else {
                      current.remove(item);
                    }
                    _form.setAndValidateField(BookingKey.tags, current);
                  },
                );
              }).toList(),
            ),
            if (tags.isErrorVisible)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  tags.error?.message ?? '',
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _form.submissionStatus.isSubmitting
                  ? null
                  : () async {
                      final success = await _form.submitForm(
                        onSubmit: (values) async {
                          await Future<void>.delayed(const Duration(seconds: 1));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🏨 Đặt phòng thành công!'),
                                backgroundColor: Color(0xFF7C3AED),
                              ),
                            );
                          }
                        },
                      );
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚠️ Vui lòng hoàn tất thông tin đặt phòng'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
              child: _form.submissionStatus.isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Hoàn Tất Đặt Phòng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

Widget _buildSectionHeader(String title, IconData icon) {
  return Row(
    children: [
      Icon(icon, color: const Color(0xFF4F46E5), size: 24),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ],
  );
}
