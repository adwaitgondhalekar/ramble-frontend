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
class MockSharedPreferences extends Mock implements SharedPreferences {}
class FakeUri extends Fake implements Uri {}
class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  late MockHttpClient mockHttpClient;
  late MockNavigatorObserver navigatorObserver;

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
    }
  ];

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(FakeRoute());
  });

  setUp(() async {
    mockHttpClient = MockHttpClient();
    navigatorObserver = MockNavigatorObserver();
    SharedPreferences.setMockInitialValues({
      'authToken': 'test-token',
    });

    // Setup default responses
    when(() => mockHttpClient.get(
      any(),
      headers: any(named: 'headers'),
    )).thenAnswer((invocation) async {
      final url = invocation.positionalArguments[0] as Uri;
      if (url.path.contains('profile')) {
        return http.Response(jsonEncode(mockProfileData), 200);
      } else if (url.path.contains('posts')) {
        return http.Response(jsonEncode(mockPosts), 200);
      } else if (url.path.contains('followers')) {
        return http.Response(jsonEncode({'total_followers': 10}), 200);
      } else if (url.path.contains('followees')) {
        return http.Response(jsonEncode({'total_following': 15}), 200);
      }
      return http.Response('', 404);
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
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byWidgetPredicate((widget) => 
        widget is Text && widget.data == 'testuser'
      ), findsWidgets);
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
      expect(find.text('Test bio'), findsOneWidget);
    });

    testWidgets('Shows correct statistics', (WidgetTester tester) async {
      await tester.pumpWidget(createProfileScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byWidgetPredicate((widget) => 
        widget is Text && widget.data == '10'
      ), findsOneWidget); // Followers
      expect(find.byWidgetPredicate((widget) => 
        widget is Text && widget.data == '15'
      ), findsOneWidget); // Following
      expect(find.byWidgetPredicate((widget) => 
        widget is Text && widget.data == '1'
      ), findsOneWidget); // Posts count
    });
  });

  group('ProfileScreen Widget Tests - Error Handling', () {
    testWidgets('Shows error when profile fetch fails', (WidgetTester tester) async {
      when(() => mockHttpClient.get(
        any(),
        headers: any(named: 'headers'),
      )).thenAnswer((_) async => http.Response('Error', 500));

      await tester.pumpWidget(createProfileScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Failed to load profile data'), findsOneWidget);
    });
  });

  group('ProfileScreen Widget Tests - Navigation', () {
    testWidgets('Edit profile navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(createProfileScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      verify(() => navigatorObserver.didPush(any(), any())).called(1);
    });

    testWidgets('Bottom navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(createProfileScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      verify(() => navigatorObserver.didReplace(
        oldRoute: any(named: 'oldRoute'),
        newRoute: any(named: 'newRoute'),
      )).called(1);
    });
  });
}