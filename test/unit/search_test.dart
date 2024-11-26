import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ramble/screens/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MockHttpClient extends Mock implements http.Client {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}
class FakeUri extends Fake implements Uri {}
class FakeRoute extends Fake implements Route {}

void main() {
  late MockHttpClient mockHttpClient;
  late MockNavigatorObserver navigatorObserver;

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
  });

  Widget createSearchScreen() {
    return MaterialApp(
      navigatorObservers: [navigatorObserver],
      home: SearchScreen(
        previousPage: 'home',
        httpClient: mockHttpClient,
      ),
    );
  }

  group('SearchScreen Widget Tests - UI Elements', () {
    testWidgets('Renders initial UI elements correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createSearchScreen());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const Key('searchIcon')), findsOneWidget);
      expect(find.byKey(const Key('searchField')), findsOneWidget);
      expect(find.byKey(const Key('bottomNavBar')), findsOneWidget);
    });

    testWidgets('Shows loading indicator when searching', (WidgetTester tester) async {
      when(() => mockHttpClient.get(any<Uri>(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return http.Response('[]', 200);
      });

      await tester.pumpWidget(createSearchScreen());
      
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(); 
      
      expect(find.byKey(const Key('searchLoadingIndicator')), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('Shows no results message when search returns empty',
        (WidgetTester tester) async {
      // Mock both API responses - search and following
      when(() => mockHttpClient.get(
        any<Uri>(),
        headers: any(named: 'headers')
      )).thenAnswer((invocation) {
        final uri = invocation.positionalArguments[0] as Uri;
        if (uri.toString().contains('search/users')) {
          return Future.value(http.Response('[]', 200)); // Empty search results
        } else {
          return Future.value(http.Response(jsonEncode({'following': []}), 200));
        }
      });

      await tester.pumpWidget(createSearchScreen());
      
      // Enter search text
      await tester.enterText(find.byType(TextField), 'nonexistent');
      
      // Wait for the search request
      await tester.pump();
      // Wait for the animations and state updates
      await tester.pumpAndSettle();

      expect(find.text('No users found.'), findsOneWidget);
    });
  });

  group('SearchScreen Widget Tests - Search Functionality', () {
    final mockSearchResults = [
      {
        'id': 1,
        'user': {
          'username': 'testuser1',
          'first_name': 'Test',
          'last_name': 'User1'
        },
        'bio': 'Test bio 1'
      }
    ];

    final mockFollowing = {
      'following': [1]
    };

    testWidgets('Displays search results correctly', (WidgetTester tester) async {
      when(() => mockHttpClient.get(
        any<Uri>(),
        headers: any(named: 'headers')
      )).thenAnswer((invocation) {
        final uri = invocation.positionalArguments[0] as Uri;
        if (uri.toString().contains('search/users')) {
          return Future.value(http.Response(jsonEncode(mockSearchResults), 200));
        } else {
          return Future.value(http.Response(jsonEncode(mockFollowing), 200));
        }
      });

      await tester.pumpWidget(createSearchScreen());
      
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('testuser1'), findsOneWidget);
      expect(find.text('Unfollow'), findsOneWidget);
    });

    testWidgets('Handles API errors gracefully', (WidgetTester tester) async {
      when(() => mockHttpClient.get(any<Uri>(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return http.Response('Server error', 500);
      });

      await tester.pumpWidget(createSearchScreen());
      
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Failed to fetch search results'), findsOneWidget);
    });

    testWidgets('Follow/unfollow updates UI correctly', (WidgetTester tester) async {
      when(() => mockHttpClient.get(
        any<Uri>(),
        headers: any(named: 'headers')
      )).thenAnswer((invocation) {
        final uri = invocation.positionalArguments[0] as Uri;
        if (uri.toString().contains('search/users')) {
          return Future.value(http.Response(jsonEncode(mockSearchResults), 200));
        } else {
          return Future.value(http.Response(jsonEncode(mockFollowing), 200));
        }
      });

      when(() => mockHttpClient.post(
        any<Uri>(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenAnswer((_) async => http.Response('{"status": "success"}', 200));

      await tester.pumpWidget(createSearchScreen());
      
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      expect(find.text('Unfollow'), findsOneWidget);

      await tester.tap(find.byKey(const Key('followButton_1')));
      await tester.pumpAndSettle();

      expect(find.text('Follow'), findsOneWidget);
    });
  });

  group('SearchScreen Widget Tests - Navigation', () {
    testWidgets('Bottom navigation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        navigatorObservers: [navigatorObserver],
        home: SearchScreen(
          previousPage: 'home',
          httpClient: mockHttpClient,
        ),
      ));

      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      verify(() => navigatorObserver.didReplace(
        oldRoute: any(named: 'oldRoute'),
        newRoute: any(named: 'newRoute'),
      )).called(1);

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      verify(() => navigatorObserver.didReplace(
        oldRoute: any(named: 'oldRoute'),
        newRoute: any(named: 'newRoute'),
      )).called(1);
    });
  });
}