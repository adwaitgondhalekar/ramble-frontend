import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramble/screens/signup_screen.dart';

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
  late SignUpState signUpState;
  List<TestResult> testResults = [];

  setUp(() {
    signUpState = SignUpState();
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
    test('valid usernames', () {
      // Test valid usernames
      var inputs = ['john123', 'user_name', 'test123'];
      for (var input in inputs) {
        var result = signUpState.validateUserName(input);
        addTestResult(
          'Username validation: valid username',
          input,
          'Valid username',
          result == null ? 'Valid username' : result,
          result == null
        );
      }
    });

    test('invalid usernames', () {
      var testCases = {
        '': 'empty username',
        'ab': 'username too short',
        '_startswith_': 'invalid start character',
        'verylongusername123456': 'username too long',
        'user@name': 'invalid characters'
      };

      testCases.forEach((input, description) {
        var result = signUpState.validateUserName(input);
        addTestResult(
          'Username validation: $description',
          input,
          'Invalid username',
          result ?? 'Unexpected valid result',
          result != null
        );
      });
    });
  });

  group('Email Validation Tests', () {
    test('valid emails', () {
      var validEmails = [
        'test@example.com',
        'user.name@domain.co.in',
        'user+label@example.com'
      ];

      for (var email in validEmails) {
        var result = signUpState.validateEmail(email);
        addTestResult(
          'Email validation: valid email',
          email,
          'Valid email',
          result == null ? 'Valid email' : result,
          result == null
        );
      }
    });

    test('invalid emails', () {
      var invalidEmails = {
        '': 'empty email',
        'invalidemail': 'missing @ symbol',
        'user@': 'missing domain',
        '@domain.com': 'missing username',
        'user@.com': 'invalid domain format'
      };

      invalidEmails.forEach((email, description) {
        var result = signUpState.validateEmail(email);
        addTestResult(
          'Email validation: $description',
          email,
          'Invalid email',
          result ?? 'Unexpected valid result',
          result != null
        );
      });
    });
  });

  group('Password Validation Tests', () {
    test('valid passwords', () {
      var validPasswords = [
        'Password123!',
        'Test@2023',
        'Complex1!Password'
      ];

      for (var password in validPasswords) {
        var result = signUpState.validatePassword(password);
        addTestResult(
          'Password validation: valid password',
          password,
          'Valid password',
          result == null ? 'Valid password' : result,
          result == null
        );
      }
    });

    test('invalid passwords', () {
      var invalidPasswords = {
        '': 'empty password',
        'pass': 'too short',
        'password': 'no number or special char',
        'Password1': 'no special char',
        'Password!': 'no number',
        '12345678!': 'no letter'
      };

      invalidPasswords.forEach((password, description) {
        var result = signUpState.validatePassword(password);
        addTestResult(
          'Password validation: $description',
          password,
          'Invalid password',
          result ?? 'Unexpected valid result',
          result != null
        );
      });
    });
  });

  group('Name Validation Tests', () {
    test('valid names', () {
      var validNames = [
        'John',
        'Mary-Jane',
        "O'Connor"
      ];

      for (var name in validNames) {
        var result = signUpState.validateFirstName(name);
        addTestResult(
          'Name validation: valid name',
          name,
          'Valid name',
          result == null ? 'Valid name' : result,
          result == null
        );
      }
    });

    test('invalid names', () {
      var invalidNames = {
        '': 'empty name',
        '123': 'numeric name',
        'John123': 'alphanumeric name',
        'John@': 'special characters'
      };

      invalidNames.forEach((name, description) {
        var result = signUpState.validateFirstName(name);
        addTestResult(
          'Name validation: $description',
          name,
          'Invalid name',
          result ?? 'Unexpected valid result',
          result != null
        );
      });
    });
  });

  group('Confirm Password Validation Tests', () {
    test('matching passwords', () {
      signUpState.password = 'Password123!';
      var result = signUpState.validateConfirmPassword('Password123!');
      addTestResult(
        'Confirm Password: matching passwords',
        'Password123!',
        'Passwords match',
        result == null ? 'Passwords match' : result,
        result == null
      );
    });

    test('non-matching passwords', () {
      signUpState.password = 'Password123!';
      var nonMatchingCases = {
        'Password123': 'different password',
        '': 'empty password',
        'DifferentPass123!': 'completely different password'
      };

      nonMatchingCases.forEach((password, description) {
        var result = signUpState.validateConfirmPassword(password);
        addTestResult(
          'Confirm Password: $description',
          password,
          'Passwords do not match',
          result ?? 'Unexpected valid result',
          result != null
        );
      });
    });
  });

  tearDownAll(() {
    final latex = File('test_results.tex');
    final latexContent = '''
\\begin{table*}[t]
\\centering
\\caption{Signup Screen Unit Test}
\\label{tab:signup_screen_unit}
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