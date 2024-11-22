import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ramble/screens/home_screen.dart';
import 'signup_screen.dart';
import 'package:ramble/service_urls.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;
  final RegExp usernameRegExp =
      RegExp(r'^(?=.{3,15}$)(?![_])[a-zA-Z0-9_]+(?<![_])$');

  String? _userName;
  String? _password;

  @override
  void initState() {
    super.initState();
    _passwordVisible = true; // Initial password visibility
  }

  String? _validateUserName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    } else if (!usernameRegExp.hasMatch(value)) {
      return 'Please enter a valid username';
    }
    return null; // Return null if validation passes
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  Future<void> loginUser(String username, String password) async {
    final url = Uri.parse('${USER_SERVICE_URL}login/');

    // Ensure the keyboard is dismissed
    FocusScope.of(context).unfocus();

    // Loading Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color.fromRGBO(0, 174, 240, 1),
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Logging in...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"username": username, "password": password}),
      );

      // Hide the loading Snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response.statusCode == 200) {
        // Login success
        String token = json.decode(response.body)['access'];
        int userid = json.decode(response.body)['user-data']['id'];
        String first_name =
            json.decode(response.body)['user-data']['user']['first_name'];
        String last_name =
            json.decode(response.body)['user-data']['user']['last_name'];
        String bio = json.decode(response.body)['user-data']['bio'];

        // Save token in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Set user data
        await prefs.setString('authToken', token);
        await prefs.setInt(
          'userId',
          userid,
        );
        await prefs.setString('username', username);
        await prefs.setString('firstName', first_name);
        await prefs.setString('lastName', last_name);
        await prefs.setString('bio', bio);

        // Set isLoggedIn to true
        await prefs.setBool('isLoggedIn', true);

        // Success Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Login successful!',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to the home screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const HomeScreen(previousPage: 'home')),
          );
        });
      } else if (response.statusCode == 400) {
        // Extract error message from the response
        String errorMessage = json.decode(response.body)['error'] ??
            'Invalid username or password';

        // Error Snackbar for invalid username or password
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Login failed: $errorMessage',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Generic server error Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'An unexpected error occurred. Status code: ${response.statusCode}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Hide the loading Snackbar in case of exception
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Network error Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Network error. Please try again.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      print('Error: $e');
    }
  }

  // void _showSuccessDialog(String message, Color color, IconData icon) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false, // Disable dismissing by tapping outside
  //     builder: (BuildContext context) {
  //       return WillPopScope(
  //         onWillPop: () async {
  //           return false; // Prevent the back button from dismissing the dialog
  //         },
  //         child: AlertDialog(
  //           backgroundColor: color,
  //           contentTextStyle: GoogleFonts.yaldevi(
  //             textStyle: const TextStyle(
  //               fontSize: 16,
  //               fontWeight: FontWeight.bold,
  //               color: Colors.white,
  //             ),
  //           ),
  //           content: Padding(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Icon(icon, color: Colors.white, size: 40),
  //                 const SizedBox(height: 20),
  //                 Text(message),
  //               ],
  //             ),
  //           ),
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(12.0),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  // void _showFailureDialog(String message, Color color, IconData icon) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: true,
  //     builder: (BuildContext context) {
  //       return WillPopScope(
  //         onWillPop: () async {
  //           Navigator.of(context).pop(); // Close only the dialog
  //           return false;
  //         },
  //         child: AlertDialog(
  //           backgroundColor: color,
  //           contentTextStyle: GoogleFonts.yaldevi(
  //             textStyle: const TextStyle(
  //               fontSize: 16,
  //               fontWeight: FontWeight.bold,
  //               color: Colors.white,
  //             ),
  //           ),
  //           content: Padding(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Icon(icon, color: Colors.white, size: 40),
  //                 const SizedBox(height: 20),
  //                 Text(message),
  //               ],
  //             ),
  //           ),
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(12.0),
  //           ),
  //         ),
  //       );
  //     },
  //   ).then((_) {
  //     // Ensure the Login screen remains on the stack after dialog dismissal
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => const Login()),
  //     );
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(62, 110, 162, 1),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(51, 60, 51, 50),
                child: Container(
                  alignment: Alignment.center,
                  constraints:
                      const BoxConstraints(minWidth: 300, minHeight: 100),
                  child: Text(
                    'Ramble',
                    style: GoogleFonts.yaldevi(
                      textStyle: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              _buildTextField(
                hintText: 'Username',
                helperText: ' ',
                validator: _validateUserName,
                onChanged: (value) => _userName = value,
                obscureText: false,
              ),
              _buildTextField(
                hintText: 'Password',
                helperText: ' ',
                validator: _validatePassword,
                onChanged: (value) => _password = value,
                obscureText: _passwordVisible,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                  icon: _passwordVisible
                      ? const Icon(Icons.visibility_off)
                      : const Icon(Icons.visibility),
                ),
              ),
              const Padding(padding: EdgeInsets.only(top: 50)),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    FocusScope.of(context).unfocus(); // Dismiss the keyboard
                    loginUser(_userName!, _password!); // Trigger login
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(0, 174, 240, 1),
                  minimumSize: const Size(150, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text(
                  'Login',
                  style: GoogleFonts.yaldevi(
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const Padding(padding: EdgeInsets.only(top: 45)),
              _buildSignUpPrompt(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required String helperText,
    required FormFieldValidator<String>? validator,
    required ValueChanged<String> onChanged,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(51, 0, 51, 10),
      child: SizedBox(
        width: 295,
        height: 65,
        child: TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validator,
          onChanged: onChanged,
          enableSuggestions: false,
          obscureText: obscureText,
          autocorrect: false,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintStyle: GoogleFonts.yaldevi(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(62, 110, 162, 0.5),
              ),
            ),
            helperText: helperText,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
            errorStyle: GoogleFonts.yaldevi(
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderSide: const BorderSide(width: 1),
              borderRadius: BorderRadius.circular(15),
            ),
            suffixIcon: suffixIcon,
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(width: 0),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpPrompt() {
    return RichText(
      text: TextSpan(
        text: 'Don\'t have an account? ',
        style: GoogleFonts.yaldevi(
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        children: <TextSpan>[
          TextSpan(
            text: 'Create',
            style: GoogleFonts.yaldevi(
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(0, 174, 240, 1),
              ),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUp()),
                );
              },
          ),
        ],
      ),
    );
  }
}
