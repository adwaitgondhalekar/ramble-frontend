import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramble/screens/login_screen.dart';
import 'package:ramble/screens/signup_screen.dart';
import 'package:google_fonts/google_fonts.dart';

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

  group('Login Widget Tests', () {
    testWidgets('renders all form fields and buttons', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 1600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(MaterialApp(home: Login()));
      await tester.pumpAndSettle();

      // App Title
      final titleFinder = find.text('Ramble');
      bool titleFound = titleFinder.evaluate().isNotEmpty;
      addTestResult(
        'UI Rendering',
        'Component Visibility',
        'Render app title',
        'Ramble title should be visible',
        titleFound ? 'Title is visible' : 'Title not found',
        titleFound
      );

      // Username field
      final usernameField = find.byKey(const Key('usernameField'));
      bool usernameFound = usernameField.evaluate().isNotEmpty;
      addTestResult(
        'UI Rendering',
        'Component Visibility',
        'Render username field',
        'Username field should be visible',
        usernameFound ? 'Field is visible' : 'Field not found',
        usernameFound
      );

      // Password field
      final passwordField = find.byKey(const Key('passwordField'));
      bool passwordFound = passwordField.evaluate().isNotEmpty;
      addTestResult(
        'UI Rendering',
        'Component Visibility',
        'Render password field',
        'Password field should be visible',
        passwordFound ? 'Field is visible' : 'Field not found',
        passwordFound
      );

      // Login button
      final loginButton = find.byKey(const Key('loginButton'));
      bool loginButtonFound = loginButton.evaluate().isNotEmpty;
      addTestResult(
        'UI Rendering',
        'Component Visibility',
        'Render login button',
        'Login button should be visible',
        loginButtonFound ? 'Button is visible' : 'Button not found',
        loginButtonFound
      );

      // Sign up prompt
      final signUpText = find.text('Don\'t have an account? ');
      final createLink = find.text('Create');
      bool promptFound = signUpText.evaluate().isNotEmpty && createLink.evaluate().isNotEmpty;
      addTestResult(
        'UI Rendering',
        'Component Visibility',
        'Render sign up prompt',
        'Sign up prompt should be visible',
        promptFound ? 'Prompt is visible' : 'Prompt not found',
        promptFound
      );
    });

    testWidgets('validates empty form fields', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Login()));
      await tester.pumpAndSettle();

      // Try to submit empty form
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle();

      final usernameError = find.text('Please enter a username');
      bool usernameErrorShown = usernameError.evaluate().isNotEmpty;
      addTestResult(
        'Form Validation',
        'Empty Field Validation',
        'Submit empty username',
        'Should show username error',
        usernameErrorShown ? 'Error shown' : 'Error not shown',
        usernameErrorShown
      );

      final passwordError = find.text('Please enter your password');
      bool passwordErrorShown = passwordError.evaluate().isNotEmpty;
      addTestResult(
        'Form Validation',
        'Empty Field Validation',
        'Submit empty password',
        'Should show password error',
        passwordErrorShown ? 'Error shown' : 'Error not shown',
        passwordErrorShown
      );
    });

    testWidgets('validates username format', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Login()));
      await tester.pumpAndSettle();

      final invalidUsernames = {
        '_invalid': 'starts with underscore',
        'a': 'too short',
        'very_long_username_123': 'too long',
        'user@name': 'special characters'
      };

      for (var username in invalidUsernames.entries) {
        await tester.enterText(find.byKey(const Key('usernameField')), username.key);
        await tester.pumpAndSettle();

        final errorShown = find.text('Please enter a valid username');
        bool hasError = errorShown.evaluate().isNotEmpty;
        addTestResult(
          'Form Validation',
          'Username Format',
          'Test invalid username: ${username.value}',
          'Should show format error',
          hasError ? 'Error shown' : 'Error not shown',
          hasError
        );
      }
    });

    testWidgets('password visibility toggle works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Login()));
      await tester.pumpAndSettle();

      // Check initial state (password should be hidden)
      final visibilityOffIcon = find.byIcon(Icons.visibility_off);
      bool initialStateCorrect = visibilityOffIcon.evaluate().isNotEmpty;
      addTestResult(
        'Password Field',
        'Initial Visibility',
        'Check initial password state',
        'Password should be hidden',
        initialStateCorrect ? 'Password is hidden' : 'Password is visible',
        initialStateCorrect
      );

      // Toggle visibility
      await tester.tap(visibilityOffIcon);
      await tester.pumpAndSettle();

      final visibilityIcon = find.byIcon(Icons.visibility);
      bool toggleSuccessful = visibilityIcon.evaluate().isNotEmpty;
      addTestResult(
        'Password Field',
        'Visibility Toggle',
        'Toggle password visibility',
        'Should show visibility icon',
        toggleSuccessful ? 'Password visible' : 'Toggle failed',
        toggleSuccessful
      );
    });

    testWidgets('shows loading state on valid submission', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Login()));
      await tester.pumpAndSettle();

      // Enter valid credentials
      await tester.enterText(find.byKey(const Key('usernameField')), 'validuser');
      await tester.enterText(find.byKey(const Key('passwordField')), 'password123');
      
      // Submit form
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pump();

      // Check for loading state
      final loadingMessage = find.text('Logging in...');
      final progressIndicator = find.byType(CircularProgressIndicator);
      bool loadingShown = loadingMessage.evaluate().isNotEmpty && progressIndicator.evaluate().isNotEmpty;

      addTestResult(
        'Login Process',
        'Loading State',
        'Submit valid credentials',
        'Should show loading indicator',
        loadingShown ? 'Loading state shown' : 'Loading state not shown',
        loadingShown
      );
    });
  });

  tearDownAll(() {
    final latex = File('login_widget_test_results.tex');
    final latexContent = '''
\\begin{table*}[t]
\\centering
\\caption{Login Screen Widget Test Results}
\\label{tab:login_screen_widget}
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