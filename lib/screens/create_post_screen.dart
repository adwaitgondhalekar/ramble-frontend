import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:ramble/service_urls.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _postController = TextEditingController();
  final int _maxPostLength = 256; // Matches the Post model constraint.
  bool _isSubmitting = false;

  Future<void> _submitPost() async {
    if (_postController.text.trim().isEmpty) {
      _showErrorSnackbar('Post content cannot be empty.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.post(
        Uri.parse('${POST_SERVICE_URL}post/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "text": _postController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        _showSuccessSnackbar('Post created successfully.');
        Navigator.pop(context, true); // Return success to refresh feed.
      } else {
        final responseData = jsonDecode(response.body);
        _showErrorSnackbar(responseData['error'] ?? 'Failed to create post.');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred while creating the post.');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color.fromRGBO(62, 110, 162, 1), // Consistent background color
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white), // White back button
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Post',
          style: GoogleFonts.yaldevi(
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: const Color.fromRGBO(62, 110, 162, 1),
        elevation: 0, // Matches the flat app bar style
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _postController,
              maxLength: _maxPostLength, // Specifies the max character limit
              maxLines:
                  null, // Allows the text field to grow vertically as needed
              decoration: InputDecoration(
                labelText: 'Write your post here...',
                labelStyle: GoogleFonts.yaldevi(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70, // Label text color
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(62, 110, 162, 1),
                  ),
                ),
              ),
              style: const TextStyle(
                color: Colors.white, // Text color inside the field
              ),
              cursorColor: Colors.white, // Cursor color
              textAlign: TextAlign.start, // Aligns text to the start
              buildCounter: (BuildContext context,
                  {int? currentLength, int? maxLength, bool? isFocused}) {
                return Text(
                  '$currentLength/$maxLength',
                  style: const TextStyle(
                    color: Colors.white, // Counter text color
                    fontSize: 12,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _isSubmitting
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(
                            0, 174, 240, 1), // Button background
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Submit Post',
                        style: GoogleFonts.yaldevi(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
