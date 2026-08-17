import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neat_form/neat_form.dart';

enum GuestField { fullName, passportNumber, dateOfBirth, seatType }

enum PaymentField { cardNumber, expiryDate, cvv, promoCode, totalAmount }

/// A complete, production-grade showcase screen integrating:
/// 1. Dynamic Form Array (`NeatFormArrayController`) with duplicate detection
/// 2. Input Formatters (Credit Card, Date, Currency, Uppercase, Masks)
/// 3. Real-time Live State & JSON Output telemetry
class DynamicCheckoutShowcaseScreen extends StatefulWidget {
  const DynamicCheckoutShowcaseScreen({super.key});

  @override
  State<DynamicCheckoutShowcaseScreen> createState() =>
      _DynamicCheckoutShowcaseScreenState();
}

class _DynamicCheckoutShowcaseScreenState
    extends State<DynamicCheckoutShowcaseScreen> {
  late final NeatFormArrayController<GuestField> _guestsController;
  late final NeatFormController<PaymentField> _paymentController;

  static const double _ticketPrice = 2500000; // 2.500.000 ₫ per guest

  @override
  void initState() {
    super.initState();

    // 1. Dynamic Form Array Controller (Guests / Passengers)
    _guestsController = NeatFormArrayController<GuestField>(
      initialItems: [
        {
          GuestField.fullName: 'NGUYEN VAN A',
          GuestField.passportNumber: 'B8291039',
          GuestField.dateOfBirth: '15/08/1995',
          GuestField.seatType: 'Economy',
        },
      ],
      itemValidators: {
        GuestField.fullName: NeatValidators.combine([
          NeatValidators.required(message: 'Vui lòng nhập họ và tên'),
          NeatValidators.minLength(3, message: 'Tên phải từ 3 ký tự trở lên'),
        ]),
        GuestField.passportNumber: NeatValidators.combine([
          NeatValidators.required(message: 'Vui lòng nhập số hộ chiếu/CCCD'),
          NeatValidators.minLength(6, message: 'Tối thiểu 6 ký tự'),
          NeatValidators.alphanumericOnly(message: 'Chỉ chứa chữ cái và chữ số'),
        ]),
        GuestField.dateOfBirth: NeatValidators.combine([
          NeatValidators.required(message: 'Vui lòng nhập ngày sinh'),
          NeatValidators.dateString(
            format: 'DD/MM/YYYY',
            mustBePast: true,
            minYear: 1900,
            message: 'Ngày sinh không hợp lệ (DD/MM/YYYY)',
          ),
        ]),
      },
      arrayValidators: [
        NeatArrayValidators.minItems(1, message: 'Cần ít nhất 1 hành khách'),
        NeatArrayValidators.maxItems(5, message: 'Tối đa 5 hành khách mỗi lượt đặt'),
        NeatArrayValidators.uniqueBy<GuestField, String>(
          (form) => form.valueOf<String>(GuestField.passportNumber),
          message: 'Số hộ chiếu không được trùng nhau giữa các hành khách',
        ),
      ],
    );

    // 2. Main Payment Form Controller
    _paymentController = NeatFormController<PaymentField>.fromValues(
      initialValues: {
        PaymentField.cardNumber: '',
        PaymentField.expiryDate: '',
        PaymentField.cvv: '',
        PaymentField.promoCode: '',
        PaymentField.totalAmount: _ticketPrice,
      },
      validators: {
        PaymentField.cardNumber: NeatValidators.combine([
          NeatValidators.required(message: 'Vui lòng nhập số thẻ ngân hàng'),
          NeatValidators.creditCard(message: 'Số thẻ ngân hàng không hợp lệ (Luhn algorithm)'),
        ]),
        PaymentField.expiryDate: NeatValidators.combine([
          NeatValidators.required(message: 'Vui lòng nhập hạn thẻ (MM/YY)'),
          NeatValidators.exactLength(5, message: 'Định dạng MM/YY'),
        ]),
        PaymentField.cvv: NeatValidators.combine([
          NeatValidators.required(message: 'Vui lòng nhập CVV'),
          NeatValidators.minLength(3, message: 'Tối thiểu 3 chữ số'),
          NeatValidators.maxLength(4, message: 'Tối đa 4 chữ số'),
          NeatValidators.numeric(message: 'CVV chỉ gồm chữ số'),
        ]),
      },
    );

    // Sync total amount whenever guest count changes
    _guestsController.addListener(_recalculateTotal);
  }

  void _recalculateTotal() {
    final count = _guestsController.length;
    _paymentController.setField(
      PaymentField.totalAmount,
      count * _ticketPrice,
    );
  }

  @override
  void dispose() {
    _guestsController.removeListener(_recalculateTotal);
    _guestsController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('✈️ Đặt Vé & Thanh Toán Toàn Diện'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_guestsController, _paymentController]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header Card
              _buildHeaderBanner(),
              const SizedBox(height: 20),

              // Section 1: Dynamic Form Array
              _buildSectionTitle(
                '1. Danh Sách Hành Khách Bay (${_guestsController.length}/5)',
                Icons.people_alt_rounded,
              ),
              const SizedBox(height: 12),

              // Global Array Error Message (e.g. min/max/duplicate passport)
              if (_guestsController.state.isErrorVisible)
                _buildErrorAlert(_guestsController.state.errorMessage),

              ..._guestsController.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildGuestCard(index, item);
              }),

              const SizedBox(height: 8),

              // Add Passenger Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                ),
                onPressed: _guestsController.length >= 5
                    ? null
                    : () {
                        _guestsController.addItem({
                          GuestField.fullName: '',
                          GuestField.passportNumber: '',
                          GuestField.dateOfBirth: '',
                          GuestField.seatType: 'Economy',
                        });
                      },
                icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF4F46E5)),
                label: Text(
                  _guestsController.length >= 5
                      ? 'Đã đạt tối đa 5 hành khách'
                      : '+ Thêm Hành Khách Mới',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                ),
              ),

              const SizedBox(height: 28),

              // Section 2: Input Formatters & Payment Form
              _buildSectionTitle(
                '2. Thông Tin Thanh Toán & Thẻ (Input Formatters & Masking)',
                Icons.credit_card_rounded,
              ),
              const SizedBox(height: 12),
              _buildPaymentCard(),

              const SizedBox(height: 28),

              // Section 3: Live State Telemetry
              _buildSectionTitle(
                '3. Dữ Liệu Form Thời Gian Thực (Live JSON Output)',
                Icons.data_object_rounded,
              ),
              const SizedBox(height: 12),
              _buildLiveStateCard(),

              const SizedBox(height: 28),

              // Submit & Reset Actions
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        _guestsController.resetArray();
                        _paymentController.resetForm();
                      },
                      child: const Text('Reset Toàn Bộ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (_guestsController.submissionStatus.isSubmitting ||
                              _paymentController.submissionStatus.isSubmitting)
                          ? null
                          : _handleFinalCheckout,
                      child: (_guestsController.submissionStatus.isSubmitting ||
                              _paymentController.submissionStatus.isSubmitting)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Xác Nhận & Xuất Vé',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 36),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'neat_form 1.2.3 Full Showcase',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Dynamic Form Array + Masking Formatters + Zero Focus Jump',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4F46E5), size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorAlert(String? message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message ?? 'Có lỗi trong danh sách',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard(int index, NeatFormArrayItem<GuestField> item) {
    final form = item.form;

    return Card(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: !form.isValid ? Colors.red.shade300 : Colors.grey.shade200,
        ),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFF4F46E5),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hành Khách #${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ID: ${item.id}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
                if (_guestsController.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    tooltip: 'Xóa hành khách',
                    onPressed: () => _guestsController.removeItemAt(index),
                  ),
              ],
            ),
            const Divider(height: 20),

            // Full Name (with Uppercase formatter)
            TextFormField(
              initialValue: form.valueOf<String>(GuestField.fullName),
              decoration: InputDecoration(
                labelText: 'Họ và Tên (In hoa không dấu)*',
                prefixIcon: const Icon(Icons.person_outline),
                errorText: form.field(GuestField.fullName).errorMessage,
              ),
              inputFormatters: [
                NeatInputFormatters.uppercase(),
              ],
              onChanged: (v) => _guestsController.setArrayField(index, GuestField.fullName, v),
            ),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Passport Number (Uppercase + Alphanumeric)
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: form.valueOf<String>(GuestField.passportNumber),
                    decoration: InputDecoration(
                      labelText: 'Số Hộ Chiếu / CCCD*',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      errorText: form.field(GuestField.passportNumber).errorMessage,
                    ),
                    inputFormatters: [
                      NeatInputFormatters.uppercase(),
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    ],
                    onChanged: (v) =>
                        _guestsController.setArrayField(index, GuestField.passportNumber, v),
                  ),
                ),
                const SizedBox(width: 12),

                // Date of Birth (Date Formatter DD/MM/YYYY)
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: form.valueOf<String>(GuestField.dateOfBirth),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Ngày Sinh (DD/MM/YYYY)*',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      errorText: form.field(GuestField.dateOfBirth).errorMessage,
                    ),
                    inputFormatters: [
                      NeatInputFormatters.date(format: NeatDateFormat.ddMMyyyy),
                    ],
                    onChanged: (v) {
                      if (v.length >= 10) {
                        _guestsController.setAndValidateArrayField(
                          index,
                          GuestField.dateOfBirth,
                          v,
                        );
                      } else {
                        _guestsController.setArrayField(
                          index,
                          GuestField.dateOfBirth,
                          v,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    final form = _paymentController.state;
    final total = form.valueOf<double>(PaymentField.totalAmount) ?? 0;
    final formattedTotal = '${total.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} ₫';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Price Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng Tiền Vé Tạm Tính:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    formattedTotal,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card Number Formatter
            TextFormField(
              initialValue: form.valueOf<String>(PaymentField.cardNumber),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số Thẻ Quốc Tế (Visa / Mastercard / JCB)*',
                prefixIcon: const Icon(Icons.credit_card),
                errorText: form.field(PaymentField.cardNumber).errorMessage,
              ),
              inputFormatters: [
                NeatInputFormatters.creditCard(),
              ],
              onChanged: (v) => _paymentController.setField(
                PaymentField.cardNumber,
                NeatCardFormatter.getCleanCardNumber(v),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Expiry Date Mask (MM/YY)
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: form.valueOf<String>(PaymentField.expiryDate),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Hạn Thẻ (MM/YY)*',
                      prefixIcon: const Icon(Icons.event_outlined),
                      errorText: form.field(PaymentField.expiryDate).errorMessage,
                    ),
                    inputFormatters: [
                      NeatInputFormatters.mask('##/##'),
                    ],
                    onChanged: (v) => _paymentController.setField(PaymentField.expiryDate, v),
                  ),
                ),
                const SizedBox(width: 12),

                // CVV Mask (###)
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: form.valueOf<String>(PaymentField.cvv),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'CVV*',
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: form.field(PaymentField.cvv).errorMessage,
                    ),
                    inputFormatters: [
                      NeatInputFormatters.mask('####'),
                    ],
                    onChanged: (v) => _paymentController.setField(PaymentField.cvv, v),
                  ),
                ),
                const SizedBox(width: 12),

                // Promo Code (Uppercase + No Spaces)
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: form.valueOf<String>(PaymentField.promoCode),
                    decoration: const InputDecoration(
                      labelText: 'Mã Giảm Giá',
                      prefixIcon: Icon(Icons.discount_outlined),
                    ),
                    inputFormatters: [
                      NeatInputFormatters.uppercase(),
                      NeatInputFormatters.noSpaces(),
                    ],
                    onChanged: (v) => _paymentController.setField(PaymentField.promoCode, v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStateCard() {
    final guestsValues = _guestsController.values;
    final paymentValues = _paymentController.state.values;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                ' neat_form State Engine Output',
                style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _guestsController.isValid && _paymentController.isValid
                      ? Colors.green.shade900
                      : Colors.orange.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _guestsController.isValid && _paymentController.isValid
                      ? 'ALL VALID ✅'
                      : 'FORM HAS ERRORS ⚠️',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 20),
          Text(
            '// Guest Array (${guestsValues.length} items):\n'
            '${guestsValues.map((g) => g.map((k, v) => MapEntry(k.name, v))).toList()}\n\n'
            '// Payment Form:\n'
            '${paymentValues.map((k, v) => MapEntry(k.name, v))}',
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 12,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFinalCheckout() async {
    final guestsValid = _guestsController.validateArray();
    final paymentValid = _paymentController.validateForm();

    if (!guestsValid || !paymentValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _guestsController.state.errorMessage ??
                '⚠️ Vui lòng kiểm tra lại các trường thông tin hành khách và thanh toán!',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Submit both forms
    await _guestsController.submitForm(
      onSubmit: (guests) async {
        await _paymentController.submitForm(
          onSubmit: (payment) async {
            await Future<void>.delayed(const Duration(seconds: 1));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '🎉 Đặt vé và thanh toán thành công cho ${guests.length} hành khách!',
                  ),
                  backgroundColor: const Color(0xFF4F46E5),
                ),
              );
            }
          },
        );
      },
    );
  }
}
