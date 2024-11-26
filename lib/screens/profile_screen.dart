import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ramble/screens/edit_profile_screen.dart';
import 'package:ramble/widgets/custom_bottom_navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'package:ramble/service_urls.dart';



class ProfileScreen extends StatefulWidget {
  final String previousPage;
  final http.Client? httpClient;  // Add this line
  
  const ProfileScreen({
    super.key, 
    required this.previousPage,
    this.httpClient,  // Add this line
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}


class _ProfileScreenState extends State<ProfileScreen> {
  List<dynamic> posts = [];
  String? username;
  String? firstName;
  String? lastName;
  String? bio;

  int followersCount = 0;
  int followingCount = 0;
  int postCount = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
  setState(() => isLoading = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final client = widget.httpClient ?? http.Client();

    // Fetch user profile details
    final profileResponse = await client.get(
        Uri.parse('${USER_SERVICE_URL}profile/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

    if (profileResponse.statusCode == 200) {
      final profileData = json.decode(profileResponse.body);

      setState(() {
        username = profileData['username'];
        firstName = profileData['first_name'];
        lastName = profileData['last_name'];
        bio = profileData['bio'];
      });
    } else {
      _showErrorSnackbar('Failed to load profile data');
      return; // Early return on error
    }

    // Fetch posts
    final postsResponse = await client.get(
      Uri.parse('${POST_SERVICE_URL}posts/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (postsResponse.statusCode == 200) {
      final List<dynamic> postData = json.decode(postsResponse.body);
      postData.sort((a, b) => DateTime.parse(b['timestamp'])
          .compareTo(DateTime.parse(a['timestamp'])));
      setState(() {
        posts = postData;
        postCount = postData.length;
      });
    } else {
      _showErrorSnackbar('Failed to load posts');
      return;
    }

    // Fetch followers count
    final followersResponse = await client.get(
      Uri.parse('${FOLLOW_SERVICE_URL}followers/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (followersResponse.statusCode == 200) {
      setState(() {
        followersCount =
            json.decode(followersResponse.body)['total_followers'];
      });
    }

    // Fetch following count
    final followingResponse = await client.get(
      Uri.parse('${FOLLOW_SERVICE_URL}followees/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (followingResponse.statusCode == 200) {
      setState(() {
        followingCount =
            json.decode(followingResponse.body)['total_following'];
      });
    }
  } catch (error) {
    _showErrorSnackbar('Error fetching profile data: $error');
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
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

  void _navigateToEditProfile() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );

    if (updated == true) {
      // Reload profile data after editing
      fetchProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(62, 110, 162, 1),
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _buildProfileBody(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2,
        onTap: _handleNavigation,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(57.0),
      child: Material(
        color: const Color.fromRGBO(62, 110, 162, 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              backgroundColor: const Color.fromRGBO(62, 110, 162, 1),
              title: Text(
                'Your Profile',
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
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProfileInfo(),
          _buildStatsSection(),
          _buildEditProfileButton(),
          const Divider(color: Colors.white70),
          _buildPostsSection(),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[300],
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username ?? 'Unknown User',
                style: GoogleFonts.yaldevi(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    firstName ?? 'First Name',
                    style: GoogleFonts.yaldevi(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    lastName ?? 'Last Name',
                    style: GoogleFonts.yaldevi(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                bio ?? 'No Bio',
                style: GoogleFonts.yaldevi(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCountColumn('Posts', postCount),
          _buildCountColumn('Followers', followersCount),
          _buildCountColumn('Following', followingCount),
        ],
      ),
    );
  }

  Widget _buildCountColumn(String label, int count) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.yaldevi(
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          count.toString(),
          style: GoogleFonts.yaldevi(
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditProfileButton() {
    return ElevatedButton(
      onPressed: _navigateToEditProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(0, 174, 240, 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        'Edit Profile',
        style: GoogleFonts.yaldevi(
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPostsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Posts',
            style: GoogleFonts.yaldevi(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          posts.isEmpty
              ? Container(
                  height: 200,
                  child: const Center(
                    child: Text(
                      'No posts yet.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildPostCard(post);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final formattedDate = DateFormat('MMM d, yyyy, h:mm a')
        .format(DateTime.parse(post['timestamp']).toLocal());
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person, color: Color(0xFF2C4B69)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        post['username'] ?? 'Anonymous',
                        style: GoogleFonts.yaldevi(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: GoogleFonts.yaldevi(
                          textStyle: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post['text'] ?? '',
                    style: GoogleFonts.yaldevi(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.thumb_up, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        post['likes']?.toString() ?? '0',
                        style: GoogleFonts.yaldevi(
                          textStyle: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(previousPage: 'profile'),
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
  }
}
