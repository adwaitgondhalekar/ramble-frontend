import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ramble/service_urls.dart';

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
  final url = Uri.parse('${USER_SERVICE_URL}signup/'); // Replace with your Django server IP

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
                'Signing up...',
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

    // Close the loading Snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (response.statusCode == 201) {
      // Success response from the server
      final data = json.decode(response.body);
      final token = data['access'];

      // Saving the token in local storage for future API calls
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', token);

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
                    'Signup successful',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

      // Delay before navigating to HomePage
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(previousPage: 'home',),
          ),
        );
      });
    } else {
      // Parse server error response
      final errorResponse = json.decode(response.body);
      String errorMessage = 'Signup failed'; // Default error message

      // Extract error details if present
      if (errorResponse.containsKey('user')) {
        final userError = errorResponse['user'];
        if (userError is Map && userError.containsKey('username')) {
          errorMessage = userError['username'][0];
        } else if (userError is Map && userError.containsKey('email')) {
          errorMessage = userError['email'][0];
        }
      }

      // Show failure Snackbar with parsed error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color.fromRGBO(0, 174, 240, 1),
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 10),
              Text(errorMessage),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    // Hide the loading Snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Show error Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Text('An error occurred. Please try again.'),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );

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
