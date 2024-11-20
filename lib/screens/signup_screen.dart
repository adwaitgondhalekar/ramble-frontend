import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  final bool _isLoading = false;

  // Define regex patterns
  final RegExp _emailRegex = RegExp(r'^\S+@\S+$');
  final RegExp nameRegex = RegExp(r"^[A-Za-z]+(?:[' -][A-Za-z]+)*$");
  final RegExp usernameRegExp =
      RegExp(r'^(?=.{3,15}$)(?![_])[a-zA-Z0-9_]+(?<![_])$');

  String? _firstName;
  String? _lastName;
  String? _userName;
  String? _email;
  String? _password;
  String? _confirmPassword;

  @override
  void initState() {
    super.initState();
    _passwordVisible = true;
    _confirmPasswordVisible = true;
  }

  String? _validateUserName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    } else if (!usernameRegExp.hasMatch(value)) {
      return 'Please enter a valid username';
    }
    return null; // Return null if validation passes
  }

  String? _validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your first name';
    } else if (!nameRegex.hasMatch(value)) {
      return 'Please enter a valid name';
    }
    return null; // Return null if validation passes
  }

  String? _validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your last name';
    } else if (!nameRegex.hasMatch(value)) {
      return 'Please enter a valid name';
    }
    return null; // Return null if validation passes
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    } else if (!_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null; // Return null if validation passes
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password'; // Message for empty password
    } else if (value.length < 8) {
      return 'Must be at least 8 characters'; // Message for length
    } else if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Must contain at least 1 letter'; // Message for letters
    } else if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Must contain at least one number'; // Message for numbers
    } else if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Must contain at least 1 special character'; // Message for special characters
    }
    return null; // Return null if validation passes
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    } else if (value != _password) {
      return 'Passwords do not match';
    }
    return null; // Return null if validation passes
  }

  Future<void> signupUser(BuildContext context, String username, String email,
      String password, String firstName, String lastName) async {
    final url = Uri.parse(
        'http://10.0.2.2:8000/signup/'); // Replace with your Django server IP

    // Show loading dialog with initial message
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color.fromRGBO(0, 174, 240, 1),
              contentTextStyle: GoogleFonts.yaldevi(
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              content: const Padding(
                padding: EdgeInsets.all(16.0), // Add padding for compactness
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20), // Adds vertical spacing
                    Text('Signing up...'),
                  ],
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0), // Rounded corners
              ),
            );
          },
        );
      },
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "user": {
            'username': username,
            'email': email,
            'password': password,
            'first_name': firstName,
            'last_name': lastName
          },
          "bio": "user bio"
        }),
      );

      // Update the dialog content upon receiving the response
      if (response.statusCode == 201) {
        // Success response from the server
        final data = json.decode(response.body);
        final token = data['token'];

        //saving the token in local store for the future api calls
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', token);


        setState(() {
          Navigator.of(context).pop(); // Close the loading dialog first
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Colors.green,
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
                      Icon(Icons.check, color: Colors.white, size: 48),
                      SizedBox(height: 20),
                      Text("Signup successful!"),
                    ],
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              );
            },
          );
        });

        // Delay before navigating to HomePage
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.pop(context); // Close the success dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen(previousPage: 'home',)),
          );
        });
      } else {
        // Failure response from the server
        setState(() {
          Navigator.of(context).pop(); // Close the loading dialog first
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color.fromRGBO(0, 174, 240, 1),
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
                      const Icon(Icons.close, color: Colors.red, size: 48),
                      const SizedBox(height: 20),
                      Text("Signup failed: ${response.body}",
                          style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              );
            },
          );
        });
      }
    } catch (e) {
      Navigator.pop(context); // Close the loading dialog
      print("Error: $e");
    }
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
                padding: const EdgeInsets.fromLTRB(51, 60, 51, 0),
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
                hintText: 'First Name',
                helperText: ' ',
                validator: _validateFirstName,
                onChanged: (value) => _firstName = value,
              ),
              _buildTextField(
                hintText: 'Last Name',
                helperText: ' ',
                validator: _validateLastName,
                onChanged: (value) => _lastName = value,
              ),
              _buildTextField(
                hintText: 'UserName',
                helperText: ' ',
                validator: _validateUserName,
                onChanged: (value) => _userName = value,
              ),
              _buildTextField(
                hintText: 'Email',
                helperText: ' ',
                validator: _validateEmail,
                onChanged: (value) => _email = value,
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
                      _passwordVisible = !_passwordVisible; // Toggle visibility
                    });
                  },
                  icon: _passwordVisible
                      ? const Icon(Icons.visibility_off)
                      : const Icon(Icons.visibility),
                ),
              ),
              _buildTextField(
                hintText: 'Confirm Password',
                helperText: ' ',
                validator: _validateConfirmPassword,
                onChanged: (value) => _confirmPassword = value,
                obscureText: _confirmPasswordVisible,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _confirmPasswordVisible =
                          !_confirmPasswordVisible; // Toggle visibility
                    });
                  },
                  icon: _confirmPasswordVisible
                      ? const Icon(Icons.visibility_off)
                      : const Icon(Icons.visibility),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(51, 30, 51, 0),
                child: SizedBox(
                  width: 295,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        FocusScope.of(context)
                            .unfocus(); // Dismiss the keyboard
                        signupUser(
                          context,
                          _userName!,
                          _email!,
                          _password!,
                          _firstName!,
                          _lastName!,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      backgroundColor: const Color.fromRGBO(0, 174, 240, 1),
                    ),
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.yaldevi(
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(51, 25, 51, 0),
                child: RichText(
                  text: TextSpan(
                    text: 'Already Have An Account? ',
                    style: GoogleFonts.yaldevi(
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Login',
                        style: GoogleFonts.yaldevi(
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(0, 174, 240, 1),
                          ),
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const Login(),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ),
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
    // Define content padding based on the presence of a suffix icon
    EdgeInsetsGeometry contentPadding = suffixIcon != null
        ? const EdgeInsets.symmetric(
            vertical: 10, horizontal: 40) // Adjusted for better alignment
        : const EdgeInsets.symmetric(
            vertical: 10, horizontal: 40); // Default padding

    return Padding(
      padding: const EdgeInsets.fromLTRB(51, 10, 51, 0),
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
            contentPadding: contentPadding,
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
}
