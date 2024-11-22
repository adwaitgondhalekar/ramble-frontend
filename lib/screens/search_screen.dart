import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ramble/service_urls.dart';
import 'package:ramble/screens/home_screen.dart';
import 'package:ramble/screens/profile_screen.dart';
import 'package:ramble/widgets/custom_bottom_navbar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.previousPage});

  final String previousPage;

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;
  bool noResultsFound = false;

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        searchResults = [];
        noResultsFound = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      noResultsFound = false;
    });

    final String searchApiUrl = '${USER_SERVICE_URL}search/users/?q=$query';
    final String followingApiUrl = '${FOLLOW_SERVICE_URL}followees/';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null || token.isEmpty) {
      _showErrorSnackbar('Authentication token is missing. Please log in again.');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Perform both API calls in parallel
      final responses = await Future.wait([
        http.get(Uri.parse(searchApiUrl), headers: {'Authorization': 'Bearer $token'}),
        http.get(Uri.parse(followingApiUrl), headers: {'Authorization': 'Bearer $token'}),
      ]);

      final searchResponse = responses[0];
      final followingResponse = responses[1];

      if (searchResponse.statusCode == 200 && followingResponse.statusCode == 200) {
        final List<dynamic> searchResultsData = jsonDecode(searchResponse.body);
        final List<dynamic> followingIds = jsonDecode(followingResponse.body)['following'];

        setState(() {
          if (searchResultsData.isEmpty) {
            noResultsFound = true;
          } else {
            // Merge search results with `isFollowing` status
            searchResults = searchResultsData.map((user) {
              return {
                'id': user['id'],
                'username': user['user']['username'],
                'firstName': user['user']['first_name'],
                'lastName': user['user']['last_name'],
                'bio': user['bio'],
                'isFollowing': followingIds.contains(user['id']),
              };
            }).toList();
          }
        });
      } else {
        _showErrorSnackbar('Failed to fetch search results or following list.');
      }
    } catch (error) {
      _showErrorSnackbar('An error occurred while searching.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _followUser(int userId, bool isFollowing) async {
    final String apiUrl = isFollowing
        ? '${FOLLOW_SERVICE_URL}unfollow/'
        : '${FOLLOW_SERVICE_URL}follow/';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null || token.isEmpty) {
      _showErrorSnackbar('Authentication token is missing. Please log in again.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'followee_id': userId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          // Update the `isFollowing` status for the specific user in `searchResults`
          for (var user in searchResults) {
            if (user['id'] == userId) {
              user['isFollowing'] = !isFollowing;
              break;
            }
          }
        });

        final successMessage = isFollowing
            ? 'You unfollowed ${searchResults.firstWhere((u) => u['id'] == userId)['username']}.'
            : 'You started following ${searchResults.firstWhere((u) => u['id'] == userId)['username']}.';

        _showSuccessSnackbar(successMessage);
      } else {
        _showErrorSnackbar('Failed to update follow status. Status code: ${response.statusCode}');
      }
    } catch (error) {
      _showErrorSnackbar('An error occurred while updating follow status.');
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

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['username'],
                      style: GoogleFonts.yaldevi(
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      '${user['firstName']} ${user['lastName']}',
                      style: GoogleFonts.yaldevi(
                        textStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _followUser(user['id'], user['isFollowing']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: user['isFollowing']
                      ? Colors.red[400]
                      : const Color.fromRGBO(0, 174, 240, 1),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  user['isFollowing'] ? 'Unfollow' : 'Follow',
                  style: GoogleFonts.yaldevi(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(62, 110, 162, 1),
      body: Column(
        children: [
          const SizedBox(height: 20), // Add spacing above the search bar
          Container(
            color: const Color.fromRGBO(62, 110, 162, 1),
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: GoogleFonts.yaldevi(
                  textStyle: const TextStyle(color: Colors.white54, fontSize: 16),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
              ),
              style: GoogleFonts.yaldevi(
                textStyle: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : searchResults.isEmpty && noResultsFound
                    ? const Center(
                        child: Text(
                          "No users found.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) =>
                            _buildUserCard(searchResults[index]),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1, // Highlight the Search screen
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(previousPage: 'search'),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(previousPage: 'search'),
              ),
            );
          }
        },
      ),
    );
  }
}
