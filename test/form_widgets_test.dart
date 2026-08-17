import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neat_form/neat_form.dart';

enum TestField { email, password, age }

enum ItemField { name, price }

Widget testApp(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      splashFactory: NoSplash.splashFactory,
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('NeatFormScope & NeatFormArrayScope', () {
    testWidgets('NeatFormScope.of and maybeOf return controller when present',
        (tester) async {
      final controller = NeatFormController<TestField>.fromValues(
        initialValues: {TestField.email: 'user@example.com'},
      );

      late NeatFormController<TestField> foundController;
      late NeatFormController<TestField>? foundMaybe;

      await tester.pumpWidget(
        testApp(
          NeatFormScope<TestField>(
            controller: controller,
            child: Builder(
              builder: (context) {
                foundController = NeatFormScope.of<TestField>(context);
                foundMaybe = NeatFormScope.maybeOf<TestField>(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(foundController, equals(controller));
      expect(foundMaybe, equals(controller));
    });

    testWidgets('NeatFormScope.maybeOf returns null when scope is missing',
        (tester) async {
      NeatFormController<TestField>? foundMaybe;

      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) {
              foundMaybe = NeatFormScope.maybeOf<TestField>(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(foundMaybe, isNull);
    });

    testWidgets('NeatFormScope.of throws FlutterError when scope is missing',
        (tester) async {
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) {
              expect(
                () => NeatFormScope.of<TestField>(context),
                throwsA(isA<FlutterError>()),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('NeatFormArrayScope of and maybeOf behavior', (tester) async {
      final arrayController = NeatFormArrayController<ItemField>(
        initialItems: [
          {ItemField.name: 'Apple', ItemField.price: 100},
        ],
      );

      late NeatFormArrayController<ItemField> foundController;
      late NeatFormArrayController<ItemField>? foundMaybe;

      await tester.pumpWidget(
        testApp(
          NeatFormArrayScope<ItemField>(
            controller: arrayController,
            child: Builder(
              builder: (context) {
                foundController = NeatFormArrayScope.of<ItemField>(context);
                foundMaybe = NeatFormArrayScope.maybeOf<ItemField>(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(foundController, equals(arrayController));
      expect(foundMaybe, equals(arrayController));
    });

    testWidgets(
        'NeatFormArrayScope.of throws FlutterError when missing, maybeOf returns null',
        (tester) async {
      NeatFormArrayController<ItemField>? foundMaybe;

      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) {
              foundMaybe = NeatFormArrayScope.maybeOf<ItemField>(context);
              expect(
                () => NeatFormArrayScope.of<ItemField>(context),
                throwsA(isA<FlutterError>()),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(foundMaybe, isNull);
    });
  });

  group('NeatFieldBuilder (Fine-Grained Scoped Reactivity)', () {
    testWidgets('renders initial value with explicit controller',
        (tester) async {
      final controller = NeatFormController<TestField>.fromValues(
        initialValues: {TestField.email: 'initial@mail.com'},
      );

      await tester.pumpWidget(
        testApp(
          NeatFieldBuilder<TestField, String>(
            controller: controller,
            field: TestField.email,
            builder: (context, state, _) {
              return Text('Email: ${state.value}');
            },
          ),
        ),
      );

      expect(find.text('Email: initial@mail.com'), findsOneWidget);
    });

    testWidgets(
        'resolves controller from NeatFormScope when controller is null',
        (tester) async {
      final controller = NeatFormController<TestField>.fromValues(
        initialValues: {TestField.email: 'scope@mail.com'},
      );

      await tester.pumpWidget(
        testApp(
          NeatFormScope<TestField>(
            controller: controller,
            child: NeatFieldBuilder<TestField, String>(
              field: TestField.email,
              builder: (context, state, _) {
                return Text('Email: ${state.value}');
              },
            ),
          ),
        ),
      );

      expect(find.text('Email: scope@mail.com'), findsOneWidget);
    });

    testWidgets('rebuilds ONLY target field when its value changes',
        (tester) async {
      final controller = NeatFormController<TestField>.fromValues(
        initialValues: {
          TestField.email: 'mail@test.com',
          TestField.password: 'secret',
        },
      );

      int emailBuildCount = 0;
      int passwordBuildCount = 0;

      await tester.pumpWidget(
        testApp(
          NeatFormScope<TestField>(
            controller: controller,
            child: Column(
              children: [
                NeatFieldBuilder<TestField, String>(
                  field: TestField.email,
                  builder: (context, state, _) {
                    emailBuildCount++;
                    return Text('Email: ${state.value}');
                  },
                ),
                NeatFieldBuilder<TestField, String>(
                  field: TestField.password,
                  builder: (context, state, _) {
                    passwordBuildCount++;
                    return Text('Password: ${state.value}');
                  },
                ),
              ],
            ),
          ),
        ),
      );

      expect(emailBuildCount, equals(1));
      expect(passwordBuildCount, equals(1));

      // Mutate ONLY email
      controller.setField(TestField.email, 'updated@test.com');
      await tester.pump();

      // Only email builder rebuilt!
      expect(emailBuildCount, equals(2));
      expect(passwordBuildCount, equals(1)); // Password untouched!
      expect(find.text('Email: updated@test.com'), findsOneWidget);
      expect(find.text('Password: secret'), findsOneWidget);

      // Mutate ONLY password
      controller.setField(TestField.password, 'new_secret');
      await tester.pump();

      // Only password builder rebuilt!
      expect(emailBuildCount, equals(2));
      expect(passwordBuildCount, equals(2));
      expect(find.text('Password: new_secret'), findsOneWidget);
    });

    testWidgets('respects buildWhen predicate', (tester) async {
      final controller = NeatFormController<TestField>.fromValues(
        initialValues: {TestField.email: 'test@mail.com'},
        validators: {
          TestField.email: NeatValidators.email(message: 'Email không hợp lệ'),
        },
      );

      int buildCount = 0;

      await tester.pumpWidget(
        testApp(
          NeatFieldBuilder<TestField, String>(
            controller: controller,
            field: TestField.email,
            buildWhen: (prev, curr) => prev.error != curr.error,
            builder: (context, state, _) {
              buildCount++;
              return Text(state.errorMessage != null
                  ? 'Error: ${state.errorMessage}'
                  : 'Valid: ${state.value}');
            },
          ),
        ),
      );

      expect(buildCount, equals(1));
      expect(find.text('Valid: test@mail.com'), findsOneWidget);

      // Change to another valid email -> error remains null -> buildWhen returns false
      controller.setField(TestField.email, 'another@mail.com');
      await tester.pump();
      expect(buildCount, equals(1)); // No rebuild!

      // Change to invalid email -> error changes, buildWhen returns true
      controller.setAndValidateField(TestField.email, 'invalid_mail');
      await tester.pump();
      expect(buildCount, equals(2));
      expect(find.text('Error: Email không hợp lệ'), findsOneWidget);
    });

    testWidgets(
        'updates cleanly when didUpdateWidget changes controller or field',
        (tester) async {
      final ctrl1 = NeatFormController<TestField>.fromValues(
        initialValues: {TestField.email: 'c1@mail.com', TestField.password: 'p1'},
      );
      final ctrl2 = NeatFormController<TestField>.fromValues(
        initialValues: {TestField.email: 'c2@mail.com', TestField.password: 'p2'},
      );

      var activeCtrl = ctrl1;
      var activeField = TestField.email;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return testApp(
              Stack(
                children: [
                  NeatFieldBuilder<TestField, String>(
                    controller: activeCtrl,
                    field: activeField,
                    builder: (context, state, _) => Text('Val: ${state.value}'),
                  ),
                  GestureDetector(
                    key: const Key('switch_button'),
                    onTap: () {
                      setState(() {
                        activeCtrl = ctrl2;
                        activeField = TestField.password;
                      });
                    },
                    child: const Text('Switch Action'),
                  ),
                ],
              ),
            );
          },
        ),
      );

      expect(find.text('Val: c1@mail.com'), findsOneWidget);

      // Tap to switch controller & field key
      await tester.tap(find.byKey(const Key('switch_button')));
      await tester.pump();

      expect(find.text('Val: p2'), findsOneWidget);

      // Mutating ctrl1 should NOT trigger rebuild anymore (unsubscribed)
      ctrl1.setField(TestField.email, 'mutated_c1@mail.com');
      await tester.pump();
      expect(find.text('Val: p2'), findsOneWidget);

      // Mutating ctrl2 SHOULD trigger rebuild (subscribed)
      ctrl2.setField(TestField.password, 'new_password');
      await tester.pump();
      expect(find.text('Val: new_password'), findsOneWidget);
    });

    testWidgets(
        'updates cleanly when didUpdateWidget changes ONLY field on same controller',
        (tester) async {
      final ctrl = NeatFormController<TestField>.fromValues(
        initialValues: {
          TestField.email: 'email@test.com',
          TestField.password: 'pass123',
        },
      );

      var activeField = TestField.email;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return testApp(
              Stack(
                children: [
                  NeatFieldBuilder<TestField, String>(
                    controller: ctrl,
                    field: activeField,
                    builder: (context, state, _) =>
                        Text('CurrentField: ${state.value}'),
                  ),
                  GestureDetector(
                    key: const Key('switch_field_button'),
                    onTap: () {
                      setState(() {
                        activeField = TestField.password;
                      });
                    },
                    child: const Text('Switch Field'),
                  ),
                ],
              ),
            );
          },
        ),
      );

      expect(find.text('CurrentField: email@test.com'), findsOneWidget);

      // Switch field key on the same controller
      await tester.tap(find.byKey(const Key('switch_field_button')));
      await tester.pump();

      expect(find.text('CurrentField: pass123'), findsOneWidget);
    });

    testWidgets('throws FlutterError when controller cannot be resolved',
        (tester) async {
      await tester.pumpWidget(
        testApp(
          NeatFieldBuilder<TestField, String>(
            field: TestField.email,
            builder: (context, state, _) => const Text('Hi'),
          ),
        ),
      );

      expect(tester.takeException(), isA<FlutterError>());
    });
  });

  group('NeatFormBuilder', () {
    testWidgets('rebuilds when form state changes', (tester) async {
      final controller = NeatFormController<TestField>.fromValues(
        initialValues: {TestField.email: 'user@mail.com'},
        validators: {
          TestField.email: NeatValidators.required(),
        },
      );

      await tester.pumpWidget(
        testApp(
          NeatFormBuilder<TestField>(
            controller: controller,
            builder: (context, state, ctrl) {
              return Text(
                  'Valid: ${state.isValid}, Submitting: ${state.submissionStatus.isSubmitting}');
            },
          ),
        ),
      );

      expect(find.text('Valid: true, Submitting: false'), findsOneWidget);

      // Set invalid value -> isValid becomes false
      controller.setAndValidateField(TestField.email, '');
      await tester.pump();
      expect(find.text('Valid: false, Submitting: false'), findsOneWidget);
    });

    testWidgets('respects buildWhen condition on NeatFormBuilder',
        (tester) async {
      final controller = NeatFormController<TestField>.fromValues(
        initialValues: {TestField.email: 'test@mail.com', TestField.password: '123'},
      );

      int buildCount = 0;

      await tester.pumpWidget(
        testApp(
          NeatFormBuilder<TestField>(
            controller: controller,
            buildWhen: (prev, curr) =>
                prev.submissionStatus != curr.submissionStatus,
            builder: (context, state, ctrl) {
              buildCount++;
              return Text('Status: ${state.submissionStatus.name}');
            },
          ),
        ),
      );

      expect(buildCount, equals(1));

      // Mutate field value -> buildWhen returns false
      controller.setField(TestField.email, 'another@mail.com');
      await tester.pump();
      expect(buildCount, equals(1)); // No rebuild!
    });

    testWidgets(
        'throws FlutterError when NeatFormBuilder has no controller or scope',
        (tester) async {
      await tester.pumpWidget(
        testApp(
          NeatFormBuilder<TestField>(
            builder: (context, state, ctrl) => const Text('Hi'),
          ),
        ),
      );

      expect(tester.takeException(), isA<FlutterError>());
    });
  });

  group('NeatFormArrayBuilder', () {
    testWidgets('rebuilds when items are added, removed, or updated',
        (tester) async {
      final arrayController = NeatFormArrayController<ItemField>(
        initialItems: [
          {ItemField.name: 'Item 1', ItemField.price: 10},
        ],
      );

      await tester.pumpWidget(
        testApp(
          NeatFormArrayBuilder<ItemField>(
            controller: arrayController,
            builder: (context, arrayState, ctrl) {
              return Column(
                children: [
                  Text('Count: ${arrayState.length}'),
                  ...arrayState.items.map(
                    (item) => Text(
                        'Item: ${item.form.valueOf(ItemField.name)} (${item.id})'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Count: 1'), findsOneWidget);
      expect(find.textContaining('Item: Item 1'), findsOneWidget);

      // Add item
      arrayController.addItem({ItemField.name: 'Item 2', ItemField.price: 20});
      await tester.pump();

      expect(find.text('Count: 2'), findsOneWidget);
      expect(find.textContaining('Item: Item 2'), findsOneWidget);

      // Remove item
      arrayController.removeItemAt(0);
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);
      expect(find.textContaining('Item: Item 1'), findsNothing);
      expect(find.textContaining('Item: Item 2'), findsOneWidget);
    });

    testWidgets(
        'throws FlutterError when NeatFormArrayBuilder has no controller or scope',
        (tester) async {
      await tester.pumpWidget(
        testApp(
          NeatFormArrayBuilder<ItemField>(
            builder: (context, state, ctrl) => const Text('Hi'),
          ),
        ),
      );

      expect(tester.takeException(), isA<FlutterError>());
    });
  });

  group('NeatSubmitButton', () {
    testWidgets(
        'triggers onPressed and shows loading indicator when submitting',
        (tester) async {
      final completer = Completer<void>();
      final controller = NeatFormController<TestField>.fromValues(
        initialValues: {TestField.email: 'user@test.com'},
      );

      await tester.pumpWidget(
        testApp(
          NeatSubmitButton<TestField>(
            controller: controller,
            onPressed: (ctrl) async {
              await ctrl.submitForm(
                onSubmit: (_) async {
                  await completer.future;
                },
              );
            },
            child: const Text('Submit Button'),
          ),
        ),
      );

      expect(find.text('Submit Button'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Tap submit
      await tester.tap(find.text('Submit Button'));
      await tester.pump(); // Start submitting

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete submission
      completer.complete();
      await tester.pump();

      expect(find.text('Submit Button'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
        'disables when disableWhenInvalid is true and form is invalid',
        (tester) async {
      final controller = NeatFormController<TestField>.fromValues(
        initialValues: {TestField.email: ''},
        validators: {
          TestField.email: NeatValidators.required(),
        },
      );

      await tester.pumpWidget(
        testApp(
          NeatSubmitButton<TestField>(
            controller: controller,
            disableWhenInvalid: true,
            onPressed: (_) {},
            child: const Text('Save'),
          ),
        ),
      );

      // Validate to make isValid false
      controller.validateForm();
      await tester.pump();

      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull); // Disabled!

      // Set valid value
      controller.setAndValidateField(TestField.email, 'valid@mail.com');
      await tester.pump();

      final enabledButton =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(enabledButton.onPressed, isNotNull); // Enabled!
    });

    testWidgets(
        'supports custom loadingWidget and null onPressed disables button',
        (tester) async {
      final controller = NeatFormController<TestField>.fromValues(
        initialValues: {TestField.email: 'user@test.com'},
      );

      await tester.pumpWidget(
        testApp(
          NeatSubmitButton<TestField>(
            controller: controller,
            loadingWidget: const Text('Loading...'),
            onPressed: null,
            child: const Text('Disabled Submit'),
          ),
        ),
      );

      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });

  group('Scopes updateShouldNotify & Builder didUpdateWidget Edge Cases', () {
    testWidgets('NeatFormScope and NeatFormArrayScope updateShouldNotify',
        (tester) async {
      final ctrl1 =
          NeatFormController<TestField>.fromValues(initialValues: {});
      final ctrl2 =
          NeatFormController<TestField>.fromValues(initialValues: {});

      final scope1 = NeatFormScope<TestField>(
        controller: ctrl1,
        child: const SizedBox.shrink(),
      );
      final scope1Same = NeatFormScope<TestField>(
        controller: ctrl1,
        child: const SizedBox.shrink(),
      );
      final scope2 = NeatFormScope<TestField>(
        controller: ctrl2,
        child: const SizedBox.shrink(),
      );

      expect(scope1.updateShouldNotify(scope1Same), isFalse);
      expect(scope1.updateShouldNotify(scope2), isTrue);

      final arrayCtrl1 = NeatFormArrayController<ItemField>();
      final arrayCtrl2 = NeatFormArrayController<ItemField>();

      final arrayScope1 = NeatFormArrayScope<ItemField>(
        controller: arrayCtrl1,
        child: const SizedBox.shrink(),
      );
      final arrayScope1Same = NeatFormArrayScope<ItemField>(
        controller: arrayCtrl1,
        child: const SizedBox.shrink(),
      );
      final arrayScope2 = NeatFormArrayScope<ItemField>(
        controller: arrayCtrl2,
        child: const SizedBox.shrink(),
      );

      expect(arrayScope1.updateShouldNotify(arrayScope1Same), isFalse);
      expect(arrayScope1.updateShouldNotify(arrayScope2), isTrue);
    });

    testWidgets('NeatFormBuilder didUpdateWidget with new controller',
        (tester) async {
      final ctrl1 = NeatFormController<TestField>.fromValues(
        initialValues: {TestField.email: 'c1@test.com'},
      );
      final ctrl2 = NeatFormController<TestField>.fromValues(
        initialValues: {TestField.email: 'c2@test.com'},
      );

      var activeCtrl = ctrl1;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return testApp(
              Stack(
                children: [
                  NeatFormBuilder<TestField>(
                    controller: activeCtrl,
                    builder: (context, state, _) {
                      return Text('Email: ${state.valueOf(TestField.email)}');
                    },
                  ),
                  GestureDetector(
                    key: const Key('switch_form_ctrl'),
                    onTap: () {
                      setState(() {
                        activeCtrl = ctrl2;
                      });
                    },
                    child: const Text('Switch Form Ctrl'),
                  ),
                ],
              ),
            );
          },
        ),
      );

      expect(find.text('Email: c1@test.com'), findsOneWidget);

      await tester.tap(find.byKey(const Key('switch_form_ctrl')));
      await tester.pump();

      expect(find.text('Email: c2@test.com'), findsOneWidget);
    });

    testWidgets('NeatFormArrayBuilder didUpdateWidget with new controller',
        (tester) async {
      final ctrl1 = NeatFormArrayController<ItemField>(
        initialItems: [
          {ItemField.name: 'Array1'},
        ],
      );
      final ctrl2 = NeatFormArrayController<ItemField>(
        initialItems: [
          {ItemField.name: 'Array2'},
        ],
      );

      var activeCtrl = ctrl1;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return testApp(
              Stack(
                children: [
                  NeatFormArrayBuilder<ItemField>(
                    controller: activeCtrl,
                    builder: (context, state, _) {
                      return Text(
                          'First: ${state.items.first.form.valueOf(ItemField.name)}');
                    },
                  ),
                  GestureDetector(
                    key: const Key('switch_array_ctrl'),
                    onTap: () {
                      setState(() {
                        activeCtrl = ctrl2;
                      });
                    },
                    child: const Text('Switch Array Ctrl'),
                  ),
                ],
              ),
            );
          },
        ),
      );

      expect(find.text('First: Array1'), findsOneWidget);

      await tester.tap(find.byKey(const Key('switch_array_ctrl')));
      await tester.pump();

      expect(find.text('First: Array2'), findsOneWidget);
    });
  });
}
