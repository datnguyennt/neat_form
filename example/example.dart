// ignore_for_file: avoid_print

import 'package:neat_form/neat_form.dart';

/// Define strongly typed form keys.
enum SignupFormKey {
  username,
  email,
  password,
  confirmPassword,
  age,
  termsAccepted,
}

/// Optional: Define a form observer for analytics, telemetry, or debug logging.
class AppFormObserver extends NeatFormObserver<SignupFormKey> {
  @override
  void onFieldChanged(SignupFormKey key, Object? value) {
    print('  [Observer] Field "${key.name}" changed to: $value');
  }

  @override
  void onValidationError(SignupFormKey key, NeatValidationError error) {
    print('  [Observer] Field "${key.name}" error: ${error.code} (params: ${error.params})');
  }

  @override
  void onSubmissionStatusChanged(NeatSubmissionStatus status) {
    print('  [Observer] Form status changed -> ${status.name}');
  }
}

void main() async {
  print('==============================================');
  print('          neat_form Standalone Example        ');
  print('==============================================\n');

  // 1. Initialize Controller with initial fields, validators & observer
  late final NeatFormController<SignupFormKey> form;
  form = NeatFormController<SignupFormKey>(
    observer: AppFormObserver(),
    initialFields: {
      SignupFormKey.username: const NeatFieldState<String>(value: ''),
      SignupFormKey.email: const NeatFieldState<String>(value: ''),
      SignupFormKey.password: const NeatFieldState<String>(value: ''),
      SignupFormKey.confirmPassword: const NeatFieldState<String>(value: ''),
      SignupFormKey.age: const NeatFieldState<int?>(value: null),
      SignupFormKey.termsAccepted: const NeatFieldState<bool>(value: false),
    },
    validators: {
      SignupFormKey.username: NeatValidators.combine([
        NeatValidators.required(message: 'Username is required'),
        NeatValidators.minLength(4, message: 'Username must be at least 4 characters'),
        NeatValidators.noSpaces(message: 'Username cannot contain spaces'),
      ]),
      SignupFormKey.email: NeatValidators.combine([
        NeatValidators.required(message: 'Email is required'),
        NeatValidators.email(message: 'Invalid email address format'),
      ]),
      SignupFormKey.password: NeatValidators.combine([
        NeatValidators.required(message: 'Password is required'),
        NeatValidators.minLength(8, message: 'Password must be at least {minLength} characters'),
        NeatValidators.passwordStrength(
          message: 'Password must contain uppercase, lowercase, digit, and special char',
        ),
      ]),
      SignupFormKey.confirmPassword: NeatValidators.combine([
        NeatValidators.required(message: 'Confirm password is required'),
        NeatValidators.match(
          () => form.getField<String>(SignupFormKey.password).value,
          message: 'Passwords do not match',
        ),
      ]),
      SignupFormKey.age: NeatValidators.combine([
        NeatValidators.required(message: 'Age is required'),
        NeatValidators.minValue(18, message: 'Must be at least 18 years old'),
      ]),
      SignupFormKey.termsAccepted: NeatValidators.mustBeTrue(
        message: 'Must accept terms and conditions',
      ),
    },
  );

  // 2. Setup Error Resolver with dynamic parameter interpolation
  final errorResolver = NeatErrorResolver<String>();
  errorResolver.register(
    NeatValidators.codeMinLength,
    (locale, params, fieldName) =>
        '${fieldName ?? "Field"} must be at least ${params["minLength"]} chars ($locale)',
  );

  // 3. Step 1: Initial Submission Attempt (Expected: Validation Errors)
  print('--- Step 1: Submitting empty form (Validation should fail) ---');
  final isSubmitted = await form.submitForm(
    onSubmit: (values) async {
      print('Form submitted successfully with values: $values');
    },
    onError: (errors) {
      print('Submission blocked! Found ${errors.length} invalid fields:');
      for (final entry in errors.entries) {
        print('  - ${entry.key.name}: ${entry.value.message ?? entry.value.code}');
      }
    },
  );
  print('Submission success: $isSubmitted');
  print('Form isDirty: ${form.fields.isDirty}, areAllFieldsValid: ${form.fields.areAllFieldsValid}\n');

  // 4. Step 2: Fill in valid values and run async uniqueness validation
  print('--- Step 2: Updating fields with valid inputs ---');
  form.setField(SignupFormKey.username, 'flutter_dev');
  form.setField(SignupFormKey.email, 'dev@example.com');
  form.setField(SignupFormKey.password, 'Secret123!');
  form.setField(SignupFormKey.confirmPassword, 'Secret123!');
  form.setField(SignupFormKey.age, 24);
  form.setField(SignupFormKey.termsAccepted, true);

  // Check async validation (e.g. API availability check with race condition guard)
  print('\n--- Step 3: Running async validation on username ---');
  await form.validateFieldAsync<String>(
    SignupFormKey.username,
    (val) async {
      // Simulate network request
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (val == 'admin' || val == 'root') {
        return const NeatValidationError('username_taken', message: 'Username is already taken');
      }
      return null; // Valid!
    },
  );
  print('Username validation passed. Error: ${form.getField<String>(SignupFormKey.username).errorMessage}\n');

  // 5. Step 4: Re-submitting valid form
  print('--- Step 4: Re-submitting valid form ---');
  final isNowSubmitted = await form.submitForm(
    onSubmit: (values) async {
      print('Sending payload to backend API: $values');
    },
  );
  print('Submission result: $isNowSubmitted');
  print('Final status: ${form.submissionStatus.name}');
  print('Raw form values: ${form.fields.toValuesMap()}\n');

  // 6. Step 5: Resetting form
  print('--- Step 5: Resetting form back to pristine state ---');
  form.resetForm();
  print('Form isDirty after reset: ${form.fields.isDirty}');
  print('Username value after reset: "${form.getField<String>(SignupFormKey.username).value}"');

  // Clean up
  form.dispose();
  print('\nDone!');
}
