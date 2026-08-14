// ignore_for_file: avoid_print

import 'package:neat_form/neat_form.dart';

enum SignupFormKey {
  email,
  password,
  confirmPassword,
  age,
  termsAccepted,
}

void main() async {
  // 1. Initialize Controller with initial fields & validators
  late final NeatFormController<SignupFormKey> form;
  form = NeatFormController<SignupFormKey>(
    initialFields: {
      SignupFormKey.email: const NeatFieldState<String>(value: ''),
      SignupFormKey.password: const NeatFieldState<String>(value: ''),
      SignupFormKey.confirmPassword: const NeatFieldState<String>(value: ''),
      SignupFormKey.age: const NeatFieldState<int?>(value: null),
      SignupFormKey.termsAccepted: const NeatFieldState<bool>(value: false),
    },
    validators: {
      SignupFormKey.email: NeatValidators.combine([
        NeatValidators.required(),
        NeatValidators.email(),
      ]),
      SignupFormKey.password: NeatValidators.combine([
        NeatValidators.required(),
        NeatValidators.minLength(8),
      ]),
      SignupFormKey.confirmPassword: NeatValidators.combine([
        NeatValidators.required(),
        NeatValidators.match(
          () => form.getField<String>(SignupFormKey.password).value,
          message: 'Passwords do not match',
        ),
      ]),
      SignupFormKey.age: NeatValidators.combine([
        NeatValidators.required(message: 'Age is required'),
        (val) => (val is int && val >= 18)
            ? null
            : const NeatValidationError('underage', message: 'Must be 18+'),
      ]),
      SignupFormKey.termsAccepted: (val) => val == true
          ? null
          : const NeatValidationError(
              'terms_required',
              message: 'Must accept terms',
            ),
    },
  );

  // 2. Setup Error Resolver with custom parameter interpolation
  final errorResolver = NeatErrorResolver<String>();
  errorResolver.register(
    NeatValidators.codeMinLength,
    (locale, params, fieldName) =>
        '${fieldName ?? "Field"} must be at least ${params["minLength"]} characters ($locale)',
  );

  // 3. Listen to state changes (supports Flutter ListenableBuilder too)
  form.addListener(() {
    print(
      'Form state updated. Is valid: ${form.fields.areAllFieldsValid}, Submission status: ${form.submissionStatus.name}',
    );
  });

  print('--- Initial Submission (expect invalid) ---');
  final isSubmitted = await form.submitForm(
    onSubmit: (values) async {
      print('Submitting values: $values');
    },
    onError: (errors) {
      print('Form errors: ${errors.keys.map((k) => k.name).toList()}');
    },
  );
  print('Form submission succeeded: $isSubmitted');

  print('\n--- Updating fields with valid data ---');
  form.setField(SignupFormKey.email, 'dev@example.com');
  form.setField(SignupFormKey.password, 'superSecret123');
  form.setField(SignupFormKey.confirmPassword, 'superSecret123');
  form.setField(SignupFormKey.age, 25);
  form.setField(SignupFormKey.termsAccepted, true);

  print('\n--- Re-submitting form ---');
  final isNowSubmitted = await form.submitForm(
    onSubmit: (values) async {
      print('Submitting to backend with values: $values');
    },
  );
  print('Form submission succeeded: $isNowSubmitted');
  print('Final status: ${form.submissionStatus.name}');

  // Clean up
  form.dispose();
}
