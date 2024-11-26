import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:ramble/screens/home_screen.dart';
import 'package:ramble/screens/create_post_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ramble/screens/profile_screen.dart';
import 'package:ramble/screens/search_screen.dart';

// Mock classes
class MockHttpClient extends Mock implements http.Client {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}
class FakeUri extends Fake implements Uri {}
class FakeMap extends Fake implements Map<String, dynamic> {}
class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  late MockHttpClient mockHttpClient;
  late MockNavigatorObserver navigatorObserver;

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

    // Set up default http response
    when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('[]', 200));
  });

  Widget createHomeScreen() {
    return MaterialApp(
      navigatorObservers: [navigatorObserver],
      home: HomeScreen(
        previousPage: 'login',
        httpClient: mockHttpClient,
      ),
    );
  }

  group('HomeScreen Widget Tests - Navigation', () {
    testWidgets('Bottom navigation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Test navigation to search screen
      await tester.tap(find.byType(BottomNavigationBar));
      await tester.pumpAndSettle();

      verify(() => navigatorObserver.didReplace(
        oldRoute: any(named: 'oldRoute'),
        newRoute: any(named: 'newRoute')
      )).called(greaterThan(0));
    });

    testWidgets('Create post button navigation works', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Act - Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert - Verify navigation to CreatePostScreen
      verify(() => navigatorObserver.didPush(any(), any())).called(1);
    });

    testWidgets('Drawer opens with correct options', (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DrawerButton));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });
  });

  group('HomeScreen Widget Tests - Post Creation Flow', () {
    testWidgets('Shows refreshed posts after returning from create post',
        (WidgetTester tester) async {
      // Arrange
      final initialPosts = [
        {
          'id': 1,
          'text': 'Initial post',
          'timestamp': '2024-11-26T12:00:00Z',
          'likedBy': [],
          'likes': 5,
          'username': 'testuser',
          'isLiked': false
        }
      ];

      final updatedPosts = [
        {
          'id': 2,
          'text': 'New post',
          'timestamp': '2024-11-26T13:00:00Z',
          'likedBy': [],
          'likes': 0,
          'username': 'testuser',
          'isLiked': false
        },
        ...initialPosts
      ];

      var apiCallCount = 0;
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        // First call returns initial posts, subsequent calls return updated posts
        if (apiCallCount++ == 0) {
          return http.Response(jsonEncode(initialPosts), 200);
        }
        return http.Response(jsonEncode(updatedPosts), 200);
      });

      // Create a MaterialApp with both screens
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [navigatorObserver],
          home: HomeScreen(previousPage: 'login', httpClient: mockHttpClient),
          routes: {
            '/create_post': (context) => CreatePostScreen(httpClient: mockHttpClient),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Initial post'), findsOneWidget);
      expect(find.text('New post'), findsNothing);

      // Navigate to create post screen
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Simulate successful post creation by navigating back with result
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop(true); // Pop with success result
      await tester.pumpAndSettle();

      // Verify posts are refreshed
      expect(find.text('New post'), findsOneWidget);
      expect(find.text('Initial post'), findsOneWidget);

      // Verify the API was called twice (initial load and refresh)
      verify(() => mockHttpClient.get(any(), headers: any(named: 'headers'))).called(2);
    });
  });

  group('HomeScreen Widget Tests - Post Interaction', () {
    testWidgets('Can like and unlike a post', (WidgetTester tester) async {
      // Arrange
      final initialPost = {
        'id': 1,
        'text': 'Test post',
        'timestamp': '2024-11-26T12:00:00Z',
        'likedBy': [],
        'likes': 5,
        'username': 'testuser',
        'isLiked': false
      };

      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(jsonEncode([initialPost]), 200));

      when(() => mockHttpClient.patch(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode({'status': 'success'}), 200));

      // Act
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Initial state
      expect(find.text('5'), findsOneWidget);
      
      // Like the post
      await tester.tap(find.byKey(const Key('likeButton_1')));
      await tester.pumpAndSettle();

      // Verify like
      expect(find.text('6'), findsOneWidget);

      // Unlike the post
      await tester.tap(find.byKey(const Key('likeButton_1')));
      await tester.pumpAndSettle();

      // Verify unlike
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Shows error when liking fails', (WidgetTester tester) async {
      // Arrange
      final post = {
        'id': 1,
        'text': 'Test post',
        'timestamp': '2024-11-26T12:00:00Z',
        'likedBy': [],
        'likes': 5,
        'username': 'testuser',
        'isLiked': false
      };

      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(jsonEncode([post]), 200));

      when(() => mockHttpClient.patch(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('Error', 500));

      // Act
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('likeButton_1')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Failed to like the post.'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // Like count shouldn't change
    });
  });
}