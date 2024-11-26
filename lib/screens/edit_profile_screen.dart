import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ramble/service_urls.dart';

// Create a service class for profile operations
class ProfileService {
  final http.Client httpClient;
  final String baseUrl;

  ProfileService({
    http.Client? httpClient,
    String? baseUrl,
  })  : httpClient = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? USER_SERVICE_URL;

  Future<Map<String, dynamic>> fetchProfile(String token) async {
    final response = await httpClient.get(
      Uri.parse('${baseUrl}profile/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
  }

  Future<void> updateProfile(
      String token, Map<String, dynamic> updatedData) async {
    final response = await httpClient.patch(
      Uri.parse('${baseUrl}profile/edit/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updatedData),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        final errorResponse = json.decode(response.body);
        if (errorResponse['user']?['username'] != null) {
          throw Exception(errorResponse['user']['username'][0]);
        }
      }
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }
}

class EditProfileScreen extends StatefulWidget {
  final ProfileService? profileService;
  final SharedPreferences? prefs;

  const EditProfileScreen({
    Key? key,
    this.profileService,
    this.prefs,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username cannot be empty';
    } else if (value.contains(' ')) {
      return 'Username cannot contain spaces';
    }
    return null;
  }
  String? validateBio(String? value) {
    if (value != null && value.length > 50) {
      return 'Bio cannot exceed 50 characters';
    }
    return null;
  }
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  late final ProfileService _profileService;
  late final Future<void> _initializationFuture;

  String? _originalUsername;
  String? _originalBio;
  String? _errorMessage;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _profileService = widget.profileService ?? ProfileService();
    _initializationFuture = _loadProfileData();
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
    try {
      final prefs = widget.prefs ?? await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      if (token == null) {
        throw Exception('No auth token found');
      }

      final data = await _profileService.fetchProfile(token);
      
      if (mounted) {
        setState(() {
          _originalUsername = data['username'] ?? '';
          _originalBio = data['bio'] ?? '';
          _usernameController.text = _originalUsername!;
          _bioController.text = _originalBio!;
          _hasChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile data: ${e.toString()}';
        });
      }
      rethrow;
    }
  }

  void _checkForChanges() {
    if (!mounted) return;

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
    });
    try {
      final prefs = widget.prefs ?? await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception('No auth token found');
      }

      final Map<String, dynamic> updatedData = {};

      if (_usernameController.text != _originalUsername) {
        updatedData['user'] = {'username': _usernameController.text};
      }

      if (_bioController.text != _originalBio) {
        updatedData['bio'] = _bioController.text;
      }

      await _profileService.updateProfile(token, updatedData);

      // Update local storage
      if (_usernameController.text != _originalUsername) {
        await prefs.setString('username', _usernameController.text);
      }
      if (_bioController.text != _originalBio) {
        await prefs.setString('bio', _bioController.text);
      }

      if (mounted) {
        setState(() {
          _hasChanges = false;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Failed to save changes. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
      return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
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
        body: FutureBuilder<void>(
          future: _initializationFuture,
          builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading profile',
                    style: const TextStyle(color: Colors.white),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initializationFuture = _loadProfileData();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Padding(
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
                    validator: validateUsername,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Bio',
                    controller: _bioController,
                    hintText: 'Enter your bio (max 50 characters)',
                    maxLines: 3,
                    validator: validateBio,
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
                    onPressed: _hasChanges && !_isSaving ? _saveChanges : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasChanges
                          ? const Color.fromRGBO(0, 174, 240, 1)
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      ));
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