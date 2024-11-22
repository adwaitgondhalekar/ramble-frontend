import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ramble/service_urls.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String? _originalUsername;
  String? _originalBio;
  String? _errorMessage;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _addListeners();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _addListeners() {
    _usernameController.addListener(_checkForChanges);
    _bioController.addListener(_checkForChanges);
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isSaving = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    try {
      final response = await http.get(
        Uri.parse('${USER_SERVICE_URL}profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _originalUsername = data['username'] ?? '';
          _originalBio = data['bio'] ?? '';
          _usernameController.text = _originalUsername!;
          _bioController.text = _originalBio!;
          _hasChanges = false; // No changes initially
        });
      } else {
        _showErrorSnackbar('Failed to load profile data.');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred while loading profile data.');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _checkForChanges() {
    final usernameChanged = _usernameController.text != _originalUsername;
    final bioChanged = _bioController.text != _originalBio;

    setState(() {
      _hasChanges = usernameChanged || bioChanged;
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    // Prepare data to send
    final Map<String, dynamic> updatedData = {};

    if (_usernameController.text != _originalUsername) {
      updatedData['user'] = {'username': _usernameController.text};
    }

    if (_bioController.text != _originalBio) {
      updatedData['bio'] = _bioController.text;
    }

    try {
      final response = await http.patch(
        Uri.parse('${USER_SERVICE_URL}profile/edit/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        // Update local data
        if (_usernameController.text != _originalUsername) {
          await prefs.setString('username', _usernameController.text);
        }
        if (_bioController.text != _originalBio) {
          await prefs.setString('bio', _bioController.text);
        }

        if (mounted) {
          Navigator.pop(context, true); // Notify success
        }
      } else if (response.statusCode == 400) {
        final errorResponse = json.decode(response.body);
        if (errorResponse['user']?['username'] != null) {
          _showErrorSnackbar(
              errorResponse['user']['username'][0]); // Username error
        } else {
          _showErrorSnackbar('Failed to save changes. Please try again.');
        }
      } else {
        _showErrorSnackbar('An unexpected error occurred. Please try again.');
      }
    } catch (e) {
      _showErrorSnackbar('Network error. Please check your connection.');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(62, 110, 162, 1),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromRGBO(62, 110, 162, 1),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.yaldevi(
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      label: 'Username',
                      controller: _usernameController,
                      hintText: 'Enter your username',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username cannot be empty';
                        } else if (value.contains(' ')) {
                          return 'Username cannot contain spaces';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Bio',
                      controller: _bioController,
                      hintText: 'Enter your bio (max 50 characters)',
                      maxLines: 3,
                      validator: (value) {
                        if (value != null && value.length > 50) {
                          return 'Bio cannot exceed 50 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _hasChanges ? _saveChanges : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasChanges
                            ? const Color.fromRGBO(0, 174, 240, 1)
                            : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.yaldevi(
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: const Color.fromRGBO(0, 0, 0, 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
