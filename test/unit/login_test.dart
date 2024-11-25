import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramble/screens/login_screen.dart';

class TestResult {
  final String testName;
  final String input;
  final String expectedOutput;
  final String actualOutput;
  final String status;

  TestResult({
    required this.testName,
    required this.input,
    required this.expectedOutput,
    required this.actualOutput,
    required this.status,
  });

  String toLatexRow() {
    String sanitizedInput = input.isEmpty ? '\\textit{(empty)}' : input.replaceAll('_', '\\_');
    return '$testName & $sanitizedInput & $expectedOutput & $actualOutput & $status \\\\ \\hline';
  }
}

void main() {
  late LoginState loginState;
  List<TestResult> testResults = [];

  setUp(() {
    loginState = LoginState();
  });

  void addTestResult(String testName, String input, String expectedOutput, String actualOutput, bool passed) {
    testResults.add(TestResult(
      testName: testName,
      input: input,
      expectedOutput: expectedOutput,
      actualOutput: actualOutput,
      status: passed ? 'Pass' : 'Fail'
    ));
  }

  group('Username Validation Tests', () {
    test('valid usernames according to pattern', () {
      var validUsernames = {
        'john123': 'alphanumeric',
        'user_name': 'with underscore',
        'test123': 'alphanumeric',
        'validuser': 'alphabetic only',
        'a1_b2': 'mixed characters'
      };

      validUsernames.forEach((username, description) {
        var result = loginState.validateUserName(username);
        addTestResult(
          'Username validation: $description',
          username,
          'null (valid username)',
          result ?? 'valid',
          result == null
        );
      });
    });

    test('invalid usernames', () {
      var invalidUsernames = {
        '': 'empty username',
        'ab': 'too short (min 3)',
        '_startswith_': 'starts with underscore',
        'ends_with_': 'ends with underscore',
        'very_long_username_123': 'too long (max 15)',
        'user@name': 'special characters',
        'user name': 'contains space',
        null: 'null value'
      };

      invalidUsernames.forEach((username, description) {
        var result = loginState.validateUserName(username as String?);
        addTestResult(
          'Username validation: $description',
          username ?? 'null',
          'Please enter a valid username',
          result ?? 'unexpectedly valid',
          result != null
        );
      });
    });
  });

  group('Password Validation Tests', () {
    test('valid passwords', () {
      var validPasswords = {
        'password123': 'simple valid password',
        'TestPassword': 'mixed case password',
        'Pass123!@#': 'complex password',
        '12345678': 'numeric password'
      };

      validPasswords.forEach((password, description) {
        var result = loginState.validatePassword(password);
        addTestResult(
          'Password validation: $description',
          password,
          'null (valid password)',
          result ?? 'valid',
          result == null
        );
      });
    });

    test('invalid passwords', () {
      var invalidPasswords = {
        '': 'empty password',
        null: 'null password'
      };

      invalidPasswords.forEach((password, description) {
        var result = loginState.validatePassword(password as String?);
        addTestResult(
          'Password validation: $description',
          password ?? 'null',
          'Please enter your password',
          result ?? 'unexpectedly valid',
          result != null
        );
      });
    });
  });

  tearDownAll(() {
    final latex = File('login_unit_test_results.tex');
    final latexContent = '''
\\begin{table*}[t]
\\centering
\\caption{Login Screen Unit Test Results}
\\label{tab:login_screen_unit}
\\begin{tabular}{|p{5cm}|p{2.5cm}|p{3cm}|p{3cm}|p{1cm}|}
\\hline
\\textbf{Test Name} & \\textbf{Input} & \\textbf{Expected Output} & \\textbf{Actual Output} & \\textbf{Status} \\\\ \\hline
${testResults.map((r) => r.toLatexRow()).join('\n')}
\\end{tabular}
\\end{table*}
''';
    latex.writeAsStringSync(latexContent);

    // Print summary
    final totalTests = testResults.length;
    final passedTests = testResults.where((r) => r.status == 'Pass').length;
    print('\nTest Summary:');
    print('Total Tests: $totalTests');
    print('Passed: $passedTests');
    print('Failed: ${totalTests - passedTests}');
    print('Success Rate: ${(passedTests / totalTests * 100).toStringAsFixed(2)}%');
  });
}