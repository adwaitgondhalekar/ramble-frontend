import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:ramble/homepage.dart';
import 'signup.dart';

class Login extends StatefulWidget {
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

  Future<void> loginUser(String email, String password) async {
    final url = Uri.parse('http://192.168.1.33:8000/login/');

    FocusScope.of(context).unfocus(); // Dismiss the keyboard

    // Show loading dialog
    final loadingDialog = showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color.fromRGBO(0, 174, 240, 1),
          contentTextStyle: GoogleFonts.yaldevi(
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 20),
                Text('Logging in...'),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        );
      },
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"username": email, "password": password}),
      );

      Navigator.of(context).pop(); // Close the loading dialog

      if (response.statusCode == 200) {
        // Login successful
        _showDialog('Login successful!', Colors.green, Icons.check_circle);
        
        // Delay and then navigate to HomePage
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        });
      } else {
        // Login failed
        String errorMessage = 'Login failed: ${json.decode(response.body)["error"]}';
        _showDialog(errorMessage, Colors.red, Icons.cancel);
        
        // Close the failure dialog after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop(); // Close the failure dialog
        });
      }
    } catch (e) {
      // Close the loading dialog if an error occurs
      Navigator.of(context).pop();
      _showDialog('An error occurred. Please try again.', Colors.red, Icons.error);
      print("Error: $e");
    }
  }

  void _showDialog(String message, Color color, IconData icon) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: color,
          contentTextStyle: GoogleFonts.yaldevi(
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 40),
                const SizedBox(height: 20),
                Text(message),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        );
      },
    );
  }

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
                  constraints: const BoxConstraints(minWidth: 300, minHeight: 100),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
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
              borderSide: BorderSide(width: 1),
              borderRadius: BorderRadius.circular(15),
            ),
            suffixIcon: suffixIcon,
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 0),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUp()),
                );
              },
          ),
        ],
      ),
    );
  }
}
