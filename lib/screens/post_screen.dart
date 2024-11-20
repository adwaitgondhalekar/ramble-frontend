import 'dart:convert'; // For JSON encoding
import 'package:http/http.dart' as http; // For making HTTP requests
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ramble/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostScreen extends StatelessWidget {
  final TextEditingController contentController = TextEditingController();
  final String username = ""; // Replace with the actual username
  final String profilePhotoUrl = "https://i.pravatar.cc/400?img=60";

  final String? previousPage; // Accept previous page info
  PostScreen({super.key, this.previousPage});

  // Function to send POST request to Flask server
  Future<void> createPost() async {
    const String apiUrl = 'http://10.0.2.2:8000/post/'; // Replace with your Flask server URL

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    // final token = 'cd5c90a9cc046399795dc6e002a31eaa360f2eb8';

    // Create the JSON data to send
    final Map<String, dynamic> postData = {
      'text': contentController.text, // Get the content from the TextField
    };

    try {
      // Make the POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json', // Tell the server we're sending JSON
          'Authorization': 'Token $token'
        },
        body: jsonEncode(postData), // Convert the map to JSON
      );

      if (response.statusCode == 201) {
        // If the server returns a 201 CREATED response
        if (kDebugMode) {
          debugPrint("Post created successfully.");
        }
        // You can navigate back to the feed screen after posting
      } else {
        // If the server returns an error
        if (kDebugMode) {
          debugPrint("Failed to create post. Error: ${response.body}");
        }
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint("Error occurred while making the POST request: $error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Post',
          style: TextStyle(color: Colors.white), // Title text color to white
        ),
        backgroundColor: const Color(0xFF2C4B69), // AppBar background color
        iconTheme: const IconThemeData(
          color: Colors.white, // Back button color to white
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (previousPage == 'login' || previousPage == 'signup') {
              // Navigate to HomeScreen if the previous page is login or signup
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen(previousPage: 'post',)),
              );
            } else {
              // Go back to the previous page in the stack
              Navigator.pop(context);
            }
          },
        ),       
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(
                      'https://example.com/your-profile-photo.jpg'),  // Replace with the actual profile photo URL
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: contentController,
                    maxLines: null,  // To make the text box grow as user types
                    decoration: const InputDecoration(
                      hintText: "What's on your mind?",
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: const Color(0xFF2C4B69),
      //   child: const Text('Post', selectionColor: Color(0xFFFFFFFF)),
      //   onPressed: () {
      //     // String postContent = contentController.text;

      //     // Call API to post the content
      //     createPost();

      //     // Navigate back to feed page
      //     Navigator.pop(context);
      //   },
      // ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Call API to post the content
          createPost();

          // Navigate back to feed page
          Navigator.pop(context);
        },
        label: const Text(
          'Post',
          style: TextStyle(
            color: Colors.white, // Text color white
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2C4B69), // Background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Capsule shape
        ),
      ),

    );
  }
}
