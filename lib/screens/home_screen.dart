import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'package:ramble/service_urls.dart';
import 'package:ramble/screens/login_screen.dart';
import 'package:ramble/widgets/custom_bottom_navbar.dart';
import 'package:ramble/screens/create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.previousPage});

  final String previousPage;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> posts = [];
  bool isLoading = true;
  bool isFetching = false; // Prevent overlapping fetches
  bool hasFetchedPosts = false; // Tracks if posts have been fetched

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts({bool isRefresh = false}) async {
    if (isFetching) return;

    setState(() {
      isFetching = true;
      if (isRefresh) posts = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final userId =
          prefs.getInt('userId'); // Current user's ID from preferences.

      final response = await http.get(
        Uri.parse('${POST_SERVICE_URL}feed/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Update isLiked for each post based on the current user's ID.
        final updatedPosts = (data as List).map((post) {
          post['isLiked'] = (post['likedBy'] as List<dynamic>).contains(userId);
          return post;
        }).toList();

        updatedPosts.sort((a, b) => DateTime.parse(b['timestamp'])
            .compareTo(DateTime.parse(a['timestamp']))); // Sort posts.

        setState(() {
          posts = updatedPosts;
          hasFetchedPosts = true;
          isLoading = false;
        });
      } else {
        _showErrorSnackbar(
            'Failed to load posts. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred while fetching posts.');
    } finally {
      setState(() => isFetching = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(62, 110, 162, 1),
      appBar: PreferredSize(
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
                  'Ramble',
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
      ),
      drawer: _buildDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              backgroundColor: const Color.fromRGBO(0, 174, 240, 1),
              color: Colors.white,
              onRefresh: () => fetchPosts(isRefresh: true),
              child: hasFetchedPosts && posts.isEmpty
                  ? _buildEmptyFeed()
                  : _buildPostList(),
            ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () async {
          final postCreated = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );

          if (postCreated == true) {
            // Refresh the feed after creating a new post.
            fetchPosts(isRefresh: true);
          }
        },
        backgroundColor: const Color.fromRGBO(0, 174, 240, 1),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchScreen(previousPage: 'home'),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(previousPage: 'home'),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration:
                const BoxDecoration(color: Color.fromRGBO(62, 110, 162, 1)),
            child: Center(
              child: Text(
                'Ramble',
                style: GoogleFonts.yaldevi(
                  textStyle: const TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(
              'Logout',
              style: GoogleFonts.yaldevi(fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('authToken');
              await prefs.remove('isLoggedIn');
              await prefs.remove('username');
              await prefs.remove('firstName');
              await prefs.remove('lastName');
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const Login()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFeed() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          'No posts to display. Create your first post or follow users to see their content!',
          textAlign: TextAlign.center,
          style: GoogleFonts.yaldevi(
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostList() {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) => _buildPostCard(posts[index]),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    if (post['isLiked'] == true) {
                      await _unlikePost(post);
                    } else {
                      await _likePost(post);
                    }
                  },
                  child: Icon(
                    post['isLiked'] == true
                        ? Icons.thumb_up
                        : Icons.thumb_up_outlined,
                    size: 20,
                    color: post['isLiked'] == true ? Colors.blue : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  post['likes'].toString(),
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
    );
  }

  Future<void> _likePost(Map<String, dynamic> post) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.patch(
        Uri.parse('${POST_SERVICE_URL}post/${post['id']}/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "action": "like",
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          post['isLiked'] = true;
          post['likes'] += 1;
        });
      } else {
        _showErrorSnackbar('Failed to like the post.');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred while liking the post.');
    }
  }

  Future<void> _unlikePost(Map<String, dynamic> post) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.patch(
        Uri.parse('${POST_SERVICE_URL}post/${post['id']}/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "action": "unlike",
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          post['isLiked'] = false;
          post['likes'] -= 1;
        });
      } else {
        _showErrorSnackbar('Failed to unlike the post.');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred while unliking the post.');
    }
  }
}
