import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ramble/screens/home_screen.dart';
import 'package:ramble/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  final String previousPage;

  const SearchScreen({super.key, required this.previousPage});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = true;
  bool noResultsFound = false;

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
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

    final String apiUrl = 'http://10.0.2.2:8000/search/users/?q=$query';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isEmpty) {
          setState(() {
            noResultsFound = true;
          });
        } else {
          setState(() {
            searchResults = data.map((userData) {
              return {
                'username': userData['user']['username'],
                'bio': userData['bio'],
              };
            }).toList();
          });
        }
      } else {
        setState(() {
          noResultsFound = true;
        });
      }
    } catch (error) {
      debugPrint('Error fetching search results: $error');
      setState(() {
        noResultsFound = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleBackNavigation(BuildContext context) {
    if (widget.previousPage == 'login' || widget.previousPage == 'signup') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen(previousPage: 'search',)),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C4B69),
        title: TextField(
          controller: _searchController,
          onChanged: _searchUsers,
          decoration: const InputDecoration(
            hintText: 'search...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white54),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _handleBackNavigation(context);
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : searchResults.isEmpty && noResultsFound
              ? const Center(child: Text("User not found"))
              : ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final result = searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(result['username'] ?? ''),
                      subtitle: Text(result['bio'] ?? ''),
                      onTap: () {
                        // Navigate to user profile or perform action on item tap
                      },
                    );
                  },
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Set to search page index
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.white,
        backgroundColor: const Color(0xFF2C4B69),
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen(previousPage: 'search',)),
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
