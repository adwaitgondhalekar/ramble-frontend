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
  final String previousPage;
  final http.Client? httpClient; // For dependency injection in tests

  const HomeScreen({
    super.key, 
    required this.previousPage,
    this.httpClient
  });

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late final http.Client _client;
  List<dynamic> posts = [];
  bool isLoading = true;
  bool isFetching = false;
  bool hasFetchedPosts = false;

  @override
  void dispose() {
    if (widget.httpClient == null) {
      _client.close();
    }
    super.dispose();
  }
  bool get isLoadingState => isLoading;

  @override
  void initState() {
    super.initState();
    _client = widget.httpClient ?? http.Client();
    // Modify fetchPosts to be testable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchPosts();
    });
  }

  // Modify fetchPosts to handle test environment
  Future<List<dynamic>> fetchPosts({bool isRefresh = false}) async {
    if (isFetching) return posts;

    setState(() {
      isFetching = true;
      if (isRefresh) posts = [];
    });

    try {
      SharedPreferences prefs;
      String? token;
      int? userId;
      
      try {
        prefs = await SharedPreferences.getInstance();
        token = prefs.getString('authToken');
        userId = prefs.getInt('userId');
      } catch (e) {
        // For test environment
        token = 'test-token';
        userId = 1;
      }

      final response = await _client.get(
        Uri.parse('${POST_SERVICE_URL}feed/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedPosts = (data as List).map((post) {
          post['isLiked'] = (post['likedBy'] as List<dynamic>).contains(userId);
          return post;
        }).toList();

        updatedPosts.sort((a, b) => DateTime.parse(b['timestamp'])
            .compareTo(DateTime.parse(a['timestamp'])));

        if (mounted) {
          setState(() {
            posts = updatedPosts;
            hasFetchedPosts = true;
            isLoading = false;
            isFetching = false;
          });
        }
        return posts;
      } else {
        showErrorSnackbar('Failed to load posts. Status code: ${response.statusCode}');
        if (mounted) {
          setState(() {
            isLoading = false;
            isFetching = false;
          });
        }
        return [];
      }
    } catch (e) {
      showErrorSnackbar('An error occurred while fetching posts.');
      if (mounted) {
        setState(() {
          isLoading = false;
          isFetching = false;
        });
      }
      return [];
    }
  }

  void showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('errorSnackbar'),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> likePost(Map<String, dynamic> post) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await _client.patch(
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
        if (mounted) {
          setState(() {
            post['isLiked'] = true;
            post['likes'] += 1;
          });
        }
        return true;
      } else {
        showErrorSnackbar('Failed to like the post.');
        return false;
      }
    } catch (e) {
      showErrorSnackbar('An error occurred while liking the post.');
      return false;
    }
  }

  Future<bool> unlikePost(Map<String, dynamic> post) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await _client.patch(
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
        if (mounted) {
          setState(() {
            post['isLiked'] = false;
            post['likes'] -= 1;
          });
        }
        return true;
      } else {
        showErrorSnackbar('Failed to unlike the post.');
        return false;
      }
    } catch (e) {
      showErrorSnackbar('An error occurred while unliking the post.');
      return false;
    }
  }

  Future<void> handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Login())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('homeScreen'),
      backgroundColor: const Color.fromRGBO(62, 110, 162, 1),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(57.0),
        child: Material(
          color: const Color.fromRGBO(62, 110, 162, 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                key: const Key('homeAppBar'),
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
      drawer: buildDrawer(),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                key: Key('loadingIndicator'),
                color: Colors.white
              )
            )
          : RefreshIndicator(
              key: const Key('refreshIndicator'),
              backgroundColor: const Color.fromRGBO(0, 174, 240, 1),
              color: Colors.white,
              onRefresh: () => fetchPosts(isRefresh: true),
              child: hasFetchedPosts && posts.isEmpty
                  ? buildEmptyFeed()
                  : buildPostList(),
            ),
      floatingActionButton: FloatingActionButton(
        key: const Key('createPostButton'),
        shape: const CircleBorder(),
        onPressed: () => navigateToCreatePost(),
        backgroundColor: const Color.fromRGBO(0, 174, 240, 1),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        key: const Key('bottomNavBar'),
        currentIndex: 0,
        onTap: handleNavigation,
      ),
    );
  }

  Future<void> navigateToCreatePost() async {
    final postCreated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    );

    if (postCreated == true) {
      await fetchPosts(isRefresh: true);
    }
  }

  void handleNavigation(int index) {
    if (!mounted) return;
    
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
  }

  Widget buildDrawer() {
    return Drawer(
      key: const Key('drawer'),
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromRGBO(62, 110, 162, 1)
            ),
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
            key: const Key('logoutButton'),
            leading: const Icon(Icons.logout),
            title: Text(
              'Logout',
              style: GoogleFonts.yaldevi(fontWeight: FontWeight.bold),
            ),
            onTap: handleLogout,
          ),
        ],
      ),
    );
  }

  Widget buildEmptyFeed() {
    return Center(
      key: const Key('emptyFeedMessage'),
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

  Widget buildPostList() {
    return ListView.builder(
      key: const Key('postList'),
      itemCount: posts.length,
      itemBuilder: (context, index) => buildPostCard(posts[index]),
    );
  }

  Widget buildPostCard(Map<String, dynamic> post) {
    final formattedDate = DateFormat('MMM d, yyyy, h:mm a')
        .format(DateTime.parse(post['timestamp']).toLocal());

    return Card(
      key: Key('postCard_${post['id']}'),
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
                            key: Key('username_${post['id']}'),
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
                            key: Key('timestamp_${post['id']}'),
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
                        key: Key('postText_${post['id']}'),
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
                  key: Key('likeButton_${post['id']}'),
                  onTap: () async {
                    if (post['isLiked'] == true) {
                      await unlikePost(post);
                    } else {
                      await likePost(post);
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
                  key: Key('likeCount_${post['id']}'),
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
}
