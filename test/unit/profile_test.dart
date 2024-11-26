import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:ramble/screens/profile_screen.dart';
import 'package:ramble/screens/edit_profile_screen.dart';
import 'package:ramble/screens/home_screen.dart';
import 'package:ramble/screens/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ramble/service_urls.dart';

// Mock classes
class MockHttpClient extends Mock implements http.Client {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}
class FakeUri extends Fake implements Uri {}
class FakeMap extends Fake implements Map<String, dynamic> {}
class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  late MockHttpClient mockHttpClient;
  late MockNavigatorObserver navigatorObserver;

  // Sample test data
  final mockProfileData = {
    'username': 'testuser',
    'first_name': 'Test',
    'last_name': 'User',
    'bio': 'Test bio',
  };

  final mockPosts = [
    {
      'id': 1,
      'text': 'Test post 1',
      'timestamp': '2024-11-26T12:00:00Z',
      'likes': 5,
      'username': 'testuser',
      'isLiked': false
    }
  ];

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(FakeMap());
    registerFallbackValue(FakeRoute());
  });

  setUp(() async {
    mockHttpClient = MockHttpClient();
    navigatorObserver = MockNavigatorObserver();

    SharedPreferences.setMockInitialValues({
      'authToken': 'test-token',
      'userId': 1,
    });

    // Set up default http responses
    when(() => mockHttpClient.get(
      any(),
      headers: any(named: 'headers'),
    )).thenAnswer((_) async {
      final uri = _.positionalArguments[0] as Uri;
      if (uri.path.contains('profile')) {
        return http.Response(jsonEncode(mockProfileData), 200);
      } else if (uri.path.contains('posts')) {
        return http.Response(jsonEncode(mockPosts), 200);
      } else if (uri.path.contains('followers')) {
        return http.Response(jsonEncode({'total_followers': 10}), 200);
      } else if (uri.path.contains('followees')) {
        return http.Response(jsonEncode({'total_following': 15}), 200);
      }
      return http.Response('[]', 404);
    });
  });

  Widget createProfileScreen() {
    return MaterialApp(
      navigatorObservers: [navigatorObserver],
      home: ProfileScreen(
        previousPage: 'home',
        httpClient: mockHttpClient,
      ),
    );
  }

  group('ProfileScreen Widget Tests - UI Elements', () {
    testWidgets('Displays loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(createProfileScreen());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Displays user information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createProfileScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Find specific widgets based on structure
      final username = find.text('testuser');
      final userInfoWidget = find.ancestor(of: username, matching: find.byType(Column));
      expect(userInfoWidget, findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
      expect(find.text('Test bio'), findsOneWidget);
    });

    testWidgets('Shows correct follower and following counts', (WidgetTester tester) async {
      await tester.pumpWidget(createProfileScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('10'), findsOneWidget); // Followers count
      expect(find.text('15'), findsOneWidget); // Following count
    });

    testWidgets('Displays posts correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createProfileScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Test post 1'), findsOneWidget);
    });

    testWidgets('Shows empty state when no posts', (WidgetTester tester) async {
      when(() => mockHttpClient.get(
        any(),
        headers: any(named: 'headers'),
      )).thenAnswer((_) async {
        final uri = _.positionalArguments[0] as Uri;
        if (uri.path.contains('posts')) {
          return http.Response('[]', 200);
        }
        return http.Response(jsonEncode(mockProfileData), 200);
      });

      await tester.pumpWidget(createProfileScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('No posts yet.'), findsOneWidget);
    });
  });

  group('ProfileScreen Widget Tests - Navigation', () {
    testWidgets('Edit profile button navigates to edit screen', (WidgetTester tester) async {
      await tester.pumpWidget(createProfileScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Clear previous interactions
      clearInteractions(navigatorObserver);

      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      verify(() => navigatorObserver.didPush(any(), any())).called(1);
    });

    testWidgets('Bottom navigation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createProfileScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Clear previous interactions
      clearInteractions(navigatorObserver);

      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      verify(() => navigatorObserver.didReplace(
        newRoute: any(named: 'newRoute'),
        oldRoute: any(named: 'oldRoute'),
      )).called(1);
    });
  });

  group('ProfileScreen Widget Tests - Error Handling', () {
    testWidgets('Shows error message when profile fetch fails', (WidgetTester tester) async {
      when(() => mockHttpClient.get(
        any(),
        headers: any(named: 'headers'),
      )).thenAnswer((_) async => http.Response('Error', 500));

      await tester.pumpWidget(createProfileScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Failed to load profile data'), findsOneWidget);
    });
  });

  group('ProfileScreen Widget Tests - Profile Update Flow', () {
    testWidgets('Profile refreshes after successful edit', (WidgetTester tester) async {
      // Setup the sequence of responses
      final responses = <http.Response>[
        http.Response(jsonEncode(mockProfileData), 200),
        http.Response(jsonEncode({
          ...mockProfileData,
          'username': 'newusername',
          'bio': 'Updated bio'
        }), 200),
      ];
      var responseIndex = 0;

      when(() => mockHttpClient.get(
        any(),
        headers: any(named: 'headers'),
      )).thenAnswer((_) async {
        final uri = _.positionalArguments[0] as Uri;
        if (uri.path.contains('profile')) {
          return responses[responseIndex++ % responses.length];
        }
        if (uri.path.contains('posts')) {
          return http.Response(jsonEncode(mockPosts), 200);
        }
        if (uri.path.contains('followers') || uri.path.contains('followees')) {
          return http.Response(jsonEncode({'total_followers': 10, 'total_following': 15}), 200);
        }
        return http.Response('[]', 404);
      });

      // Initial load
      await tester.pumpWidget(createProfileScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      final usernameInProfile = find.descendant(
        of: find.byType(Column),
        matching: find.text('testuser'),
      );
      expect(usernameInProfile, findsOneWidget);

      // Trigger edit and refresh
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();
      
      Navigator.of(tester.element(find.byType(ProfileScreen))).pop(true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      final newUsernameInProfile = find.descendant(
        of: find.byType(Column),
        matching: find.text('newusername'),
      );
      expect(newUsernameInProfile, findsOneWidget);
    });
  });
}