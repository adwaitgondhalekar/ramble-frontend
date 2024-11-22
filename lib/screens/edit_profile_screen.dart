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

  String? _initialUsername;
  String? _initialBio;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    // Add listeners to detect changes in text fields
    _usernameController.addListener(_checkForChanges);
    _bioController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _initialUsername = prefs.getString('username') ?? 'Unknown User';
      _initialBio = prefs.getString('bio') ?? 'No Bio';
      _usernameController.text = _initialUsername!;
      _bioController.text = _initialBio!;
    });
  }

  bool _hasChanges = false;

  void _checkForChanges() {
    final isUsernameChanged = _usernameController.text != _initialUsername;
    final isBioChanged = _bioController.text != _initialBio;

    setState(() {
      _hasChanges = isUsernameChanged || isBioChanged;
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    setState(() {
      _isSaving = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    // Prepare updated data
    final updatedData = {
      'user': {'username': _usernameController.text},
      'bio': _bioController.text,
    };

    try {
      // Make API call
      final response = await http.patch(
        Uri.parse('${USER_SERVICE_URL}profile/edit/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        // Update shared preferences
        await prefs.setString('username', _usernameController.text);
        await prefs.setString('bio', _bioController.text);

        // Return to profile screen with success
        if (mounted) {
          Navigator.pop(context, true); // Pass `true` to indicate changes
        }
      } else {
        _showErrorSnackbar('Failed to save changes. Please try again.');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
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
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
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
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Bio',
                      controller: _bioController,
                      hintText: 'Enter your bio',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 40),
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label cannot be empty';
            }
            return null;
          },
        ),
      ],
    );
  }
}
