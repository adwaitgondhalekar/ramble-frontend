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
  SignUpState createState() => SignUpState();
}

class SignUpState extends State<SignUp> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;
  final bool isLoading = false;

  // Define regex patterns
  final RegExp emailRegex = RegExp(r'^\S+@\S+$');
  final RegExp nameRegex = RegExp(r"^[A-Za-z]+(?:[' -][A-Za-z]+)*$");
  final RegExp usernameRegExp =
      RegExp(r'^(?=.{3,15}$)(?![_])[a-zA-Z0-9_]+(?<![_])$');

  String? firstName;
  String? lastName;
  String? userName;
  String? email;
  String? password;
  String? confirmPassword;

  @override
  void initState() {
    super.initState();
    passwordVisible = true;
    confirmPasswordVisible = true;
  }

  String? validateUserName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    } else if (!usernameRegExp.hasMatch(value)) {
      return 'Please enter a valid username';
    }
    return null; // Return null if validation passes
  }

  String? validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your first name';
    } else if (!nameRegex.hasMatch(value)) {
      return 'Please enter a valid name';
    }
    return null; // Return null if validation passes
  }

  String? validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your last name';
    } else if (!nameRegex.hasMatch(value)) {
      return 'Please enter a valid name';
    }
    return null; // Return null if validation passes
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    } else if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null; // Return null if validation passes
  }

  String? validatePassword(String? value) {
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

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    } else if (value != password) {
      return 'Passwords do not match';
    }
    return null; // Return null if validation passes
  }

  Future<void> signupUser(BuildContext context, String username, String email,
      String password, String firstName, String lastName) async {
    final url =
        Uri.parse('${USER_SERVICE_URL}signup/'); // Replace with your server URL

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
              builder: (context) => HomeScreen(
                previousPage: 'home',
              ),
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
        key: const Key('signUpScrollView'),
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
                key: Key('firstNameField'),
                hintText: 'First Name',
                helperText: ' ',
                validator: validateFirstName,
                onChanged: (value) => firstName = value,
              ),
              _buildTextField(
                key: Key('lastNameField'),
                hintText: 'Last Name',
                helperText: ' ',
                validator: validateLastName,
                onChanged: (value) => lastName = value,
              ),
              _buildTextField(
                key: Key('userNameField'),
                hintText: 'UserName',
                helperText: ' ',
                validator: validateUserName,
                onChanged: (value) => userName = value,
              ),
              _buildTextField(
                key: Key('emailField'),
                hintText: 'Email',
                helperText: ' ',
                validator: validateEmail,
                onChanged: (value) => email = value,
              ),
              _buildTextField(
                key: Key('passwordField'),
                hintText: 'Password',
                helperText: ' ',
                validator: validatePassword,
                onChanged: (value) => password = value,
                obscureText: passwordVisible,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      passwordVisible = !passwordVisible; // Toggle visibility
                    });
                  },
                  icon: passwordVisible
                      ? const Icon(Icons.visibility_off)
                      : const Icon(Icons.visibility),
                ),
              ),
              _buildTextField(
                key: Key('confirmPasswordField'),
                hintText: 'Confirm Password',
                helperText: ' ',
                validator: validateConfirmPassword,
                onChanged: (value) => confirmPassword = value,
                obscureText: confirmPasswordVisible,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      confirmPasswordVisible =
                          !confirmPasswordVisible; // Toggle visibility
                    });
                  },
                  icon: confirmPasswordVisible
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
                          userName!,
                          email!,
                          password!,
                          firstName!,
                          lastName!,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already Have An Account? ',
                      style: GoogleFonts.yaldevi(
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    TextButton(
                      key: Key('loginButton'),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const Login(),
                          ),
                        );
                      },
                      child: Text(
                        'Login',
                        style: GoogleFonts.yaldevi(
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(0, 174, 240, 1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    Key? key,
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
          key: key,
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
