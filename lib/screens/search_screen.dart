
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ramble/service_urls.dart';
import 'package:ramble/screens/home_screen.dart';
import 'package:ramble/screens/profile_screen.dart';
import 'package:ramble/widgets/custom_bottom_navbar.dart';
class SearchScreen extends StatefulWidget {
  final String previousPage;
  final http.Client? httpClient;

  const SearchScreen({
    super.key,
    required this.previousPage,
    this.httpClient,
  });

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;
  bool noResultsFound = false;
  String? errorMessage;
  late final http.Client _client;

  @override
  void initState() {
    super.initState();
    _client = widget.httpClient ?? http.Client();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (widget.httpClient == null) {
      _client.close();
    }
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        searchResults = [];
        noResultsFound = false; // Reset noResultsFound
        isLoading = false;
        errorMessage = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      noResultsFound = false;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        setState(() {
          errorMessage = 'Authentication token is missing';
          isLoading = false;
        });
        return;
      }

      final searchApiUrl = Uri.parse('${USER_SERVICE_URL}search/users/?q=$query');
      final followingApiUrl = Uri.parse('${FOLLOW_SERVICE_URL}followees/');

      final responses = await Future.wait([
        _client.get(searchApiUrl, headers: {'Authorization': 'Bearer $token'}),
        _client.get(followingApiUrl, headers: {'Authorization': 'Bearer $token'}),
      ]).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      final searchResponse = responses[0];
      final followingResponse = responses[1];

      if (searchResponse.statusCode == 200 && followingResponse.statusCode == 200) {
        final List<dynamic> searchResultsData = jsonDecode(searchResponse.body);
        final List<dynamic> followingIds = jsonDecode(followingResponse.body)['following'];

        setState(() {
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
          noResultsFound = searchResults.isEmpty && query.trim().isNotEmpty; // Update noResultsFound here
          isLoading = false;
          errorMessage = null;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch search results';
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'An error occurred while searching';
          isLoading = false;
          searchResults = [];
        });
      }
    }
  }

  Future<void> _followUser(Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final isFollowing = user['isFollowing'] as bool;
      
      final response = await _client.post(
        Uri.parse('${FOLLOW_SERVICE_URL}${isFollowing ? 'unfollow/' : 'follow/'}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'followee_id': user['id']}),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          final index = searchResults.indexWhere((u) => u['id'] == user['id']);
          if (index != -1) {
            searchResults[index]['isFollowing'] = !isFollowing;
          }
        });
        _showSuccessSnackbar(
          '${isFollowing ? 'Unfollowed' : 'Started following'} ${user['username']}'
        );
      } else {
        _showErrorSnackbar('Failed to update follow status');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Network error occurred');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('errorSnackBar'),
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('successSnackBar'),
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(62, 110, 162, 1),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildSearchBar(),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        key: const Key('bottomNavBar'),
        currentIndex: 1,
        onTap: _handleNavigation,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        key: const Key('searchField'),
        controller: _searchController,
        onChanged: _searchUsers,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search users...',
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, key: Key('searchIcon'), color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
  if (isLoading) {
    return const Center(
      child: CircularProgressIndicator(
        key: Key('searchLoadingIndicator'),
        color: Colors.white,
      ),
    );
  }

  if (errorMessage != null) {
    return Center(
      child: Text(
        errorMessage!,
        style: const TextStyle(color: Colors.red),
        textAlign: TextAlign.center,
      ),
    );
  }

  if (noResultsFound) {
    return const Center(
      child: Text(
        'No users found.',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  if (searchResults.isEmpty) {
    return const SizedBox.shrink();
  }

  return ListView.builder(
    key: const Key('searchResultsList'),
    itemCount: searchResults.length,
    itemBuilder: (context, index) => _buildUserCard(searchResults[index]),
  );
}

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      key: Key('userCard_${user['id']}'),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['username'],
                    key: Key('username_${user['id']}'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${user['firstName']} ${user['lastName']}',
                    key: Key('fullName_${user['id']}'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              key: Key('followButton_${user['id']}'),
              onPressed: () => _followUser(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: user['isFollowing']
                    ? Colors.red[400]
                    : const Color.fromRGBO(0, 174, 240, 1),
              ),
              child: Text(
                user['isFollowing'] ? 'Unfollow' : 'Follow',
                key: Key('followButtonText_${user['id']}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(int index) {
    if (!mounted) return;
    
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
  }
}