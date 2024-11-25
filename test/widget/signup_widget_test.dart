import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramble/screens/signup_screen.dart';
import 'package:ramble/screens/login_screen.dart';

class WidgetTestResult {
  final String testCategory;
  final String testCase;
  final String testAction;
  final String expectedBehavior;
  final String actualBehavior;
  final String status;

  WidgetTestResult({
    required this.testCategory,
    required this.testCase,
    required this.testAction,
    required this.expectedBehavior,
    required this.actualBehavior,
    required this.status,
  });

  String toLatexRow() {
    return '$testCategory & $testCase & $testAction & $expectedBehavior & $actualBehavior & $status \\\\ \\hline';
  }
}

void main() {
  List<WidgetTestResult> testResults = [];

  void addTestResult(String category, String testCase, String action, String expected, String actual, bool passed) {
    testResults.add(WidgetTestResult(
      testCategory: category,
      testCase: testCase,
      testAction: action,
      expectedBehavior: expected,
      actualBehavior: actual,
      status: passed ? 'Pass' : 'Fail'
    ));
  }

  group('SignUp Widget Tests', () {
    testWidgets('renders all form fields and buttons', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 1600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(MaterialApp(home: SignUp()));
      await tester.pumpAndSettle();

      // Check each widget and record result
      var widgetsToFind = {
        'First Name': 'First name field',
        'Last Name': 'Last name field',
        'UserName': 'Username field',
        'Email': 'Email field',
        'Password': 'Password field',
        'Confirm Password': 'Confirm password field',
        'Sign Up': 'Sign up button',
        'Already Have An Account? ': 'Login prompt text',
        'Login': 'Login link'
      };

      widgetsToFind.forEach((widget, description) {
        bool found = find.text(widget).evaluate().isNotEmpty;
        addTestResult(
          'UI Rendering',
          'Component Visibility',
          'Render $description',
          'Component should be visible',
          found ? 'Component is visible' : 'Component not found',
          found
        );
      });
    });

    testWidgets('shows validation errors on empty submission', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 1600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(MaterialApp(home: SignUp()));
      await tester.ensureVisible(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      var expectedErrors = {
        'Please enter your first name': 'First name validation',
        'Please enter your last name': 'Last name validation',
        'Please enter a username': 'Username validation',
        'Please enter your email': 'Email validation',
        'Please enter your password': 'Password validation'
      };

      expectedErrors.forEach((error, description) {
        bool found = find.text(error).evaluate().isNotEmpty;
        addTestResult(
          'Form Validation',
          'Empty Field Validation',
          'Submit form without $description',
          'Should show error message',
          found ? 'Error message displayed' : 'Error message not found',
          found
        );
      });
    });

    testWidgets('toggles password visibility', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 1600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(MaterialApp(home: SignUp()));
      await tester.ensureVisible(find.byKey(Key('passwordField')));
      await tester.pumpAndSettle();

      final textFieldFinder = find.descendant(
        of: find.byKey(Key('passwordField')),
        matching: find.byType(TextField),
      );

      // Initial state
      TextField textField = tester.widget<TextField>(textFieldFinder);
      bool initiallyObscured = textField.obscureText;
      addTestResult(
        'Password Field',
        'Initial Visibility',
        'Check initial password field state',
        'Password should be obscured',
        initiallyObscured ? 'Password is obscured' : 'Password is visible',
        initiallyObscured
      );

      // Toggle visibility
      await tester.tap(find.byIcon(Icons.visibility_off).first);
      await tester.pumpAndSettle();
      textField = tester.widget<TextField>(textFieldFinder);
      bool toggledState = !textField.obscureText;
      addTestResult(
        'Password Field',
        'Toggle Visibility',
        'Tap visibility toggle button',
        'Password visibility should toggle',
        toggledState ? 'Password was toggled to visible' : 'Password was toggled to obscured',
        toggledState
      );
    });

    testWidgets('validates form input', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 1600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(MaterialApp(home: SignUp()));

      var invalidInputs = {
        'firstNameField': {'input': '123', 'error': 'Please enter a valid name'},
        'lastNameField': {'input': '456', 'error': 'Please enter a valid name'},
        'userNameField': {'input': 'u', 'error': 'Please enter a valid username'},
        'emailField': {'input': 'invalid-email', 'error': 'Please enter a valid email'},
        'passwordField': {'input': 'weak', 'error': 'Must be at least 8 characters'},
        'confirmPasswordField': {'input': 'different', 'error': 'Passwords do not match'}
      };

      for (var field in invalidInputs.entries) {
        await tester.enterText(find.byKey(Key(field.key)), field.value['input']!);
        addTestResult(
          'Form Validation',
          'Invalid Input',
          'Enter invalid input in ${field.key}',
          'Should accept input',
          'Input entered successfully',
          true
        );
      }

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      for (var field in invalidInputs.entries) {
        bool errorFound = find.text(field.value['error']!).evaluate().isNotEmpty;
        addTestResult(
          'Form Validation',
          'Error Message',
          'Check error message for ${field.key}',
          'Should show error message',
          errorFound ? 'Error message displayed' : 'Error message not found',
          errorFound
        );
      }
    });

    testWidgets('navigates to Login screen on tapping Login button', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SignUp()));
      await tester.ensureVisible(find.byKey(Key('loginButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('loginButton')));
      await tester.pumpAndSettle();

      bool navigated = find.byType(Login).evaluate().isNotEmpty;
      addTestResult(
        'Navigation',
        'Login Navigation',
        'Tap login button',
        'Should navigate to login screen',
        navigated ? 'Navigation successful' : 'Navigation failed',
        navigated
      );
    });
  });

  tearDownAll(() {
    final latex = File('widget_test_results.tex');
    final latexContent = '''
\\begin{table*}[t]
\\centering
\\caption{Signup Screen Widget Test Results}
\\label{tab:signup_screen_widget}
\\begin{tabular}{|p{2.5cm}|p{2.5cm}|p{3cm}|p{3cm}|p{3cm}|p{1cm}|}
\\hline
\\textbf{Category} & \\textbf{Test Case} & \\textbf{Action} & \\textbf{Expected Behavior} & \\textbf{Actual Behavior} & \\textbf{Status} \\\\ \\hline
${testResults.map((r) => r.toLatexRow()).join('\n')}
\\end{tabular}
\\end{table*}
''';
    latex.writeAsStringSync(latexContent);

    // Print summary
    final totalTests = testResults.length;
    final passedTests = testResults.where((r) => r.status == 'Pass').length;
    print('\nWidget Test Summary:');
    print('Total Tests: $totalTests');
    print('Passed: $passedTests');
    print('Failed: ${totalTests - passedTests}');
    print('Success Rate: ${(passedTests / totalTests * 100).toStringAsFixed(2)}%');
  });
}