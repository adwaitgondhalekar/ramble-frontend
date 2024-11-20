import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ramble/screens/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String previousPage; // Accept previous page info
  const ProfileScreen({super.key, required this.previousPage});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = '';
  String bio = '';
  int followersCount = 0;
  int followingCount = 0;
  int postCount = 0;

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    const String apiUrl = 'http://10.0.2.2:8000/profile/';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          username = data['user']['username'];
          bio = data['bio'];
          followersCount = data['followers_count'];
          followingCount = data['following_count'];
          postCount = data['post_count'];
        });
      } else {
        debugPrint('Failed to load profile data: ${response.body}');
      }
    } catch (error) {
      debugPrint('Error fetching profile data: $error');
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
        title: const Text('ramble', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C4B69),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _handleBackNavigation(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Segment 1: Profile Picture, Name, Country, and Bio
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: const NetworkImage('https://example.com/profile.jpg'), // Replace with actual URL
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(width: 20),
                // Name, Country, Bio
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const Text('India', style: TextStyle(fontSize: 14, color: Colors.grey)), // Static country value
                    Text(bio, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          // Segment 2: Posts, Followers, Following
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('POSTS', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text('$postCount'),
                  ],
                ),
                Column(
                  children: [
                    const Text('FOLLOWERS', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text('$followersCount'),
                  ],
                ),
                Column(
                  children: [
                    const Text('FOLLOWING', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text('$followingCount'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // Segment 3: Edit Profile Button
          ElevatedButton(
            onPressed: () {
              // Edit profile action
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              child: Text('Edit Profile'),
            ),
          ),
          const Divider(),
          // Segment 4: User Posts
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('All posts', style: TextStyle(fontWeight: FontWeight.bold)),
                  // Add a ListView or GridView to show all posts made by the user
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
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
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(previousPage: 'profile',),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchScreen(previousPage: 'profile'),
              ),
            );
          }
        },
        selectedItemColor: Colors.white,
        backgroundColor: const Color(0xFF2C4B69),
      ),
    );
  }
}
