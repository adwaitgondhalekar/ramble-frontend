import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:ramble/screens/create_post_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock classes
class MockHttpClient extends Mock implements http.Client {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}
class FakeUri extends Fake implements Uri {}

void main() {
  late MockHttpClient mockHttpClient;
  late MockNavigatorObserver navigatorObserver;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() async {
    mockHttpClient = MockHttpClient();
    navigatorObserver = MockNavigatorObserver();

    SharedPreferences.setMockInitialValues({
      'authToken': 'test-token',
    });
  });

  Widget createTestApp() {
    return MaterialApp(
      navigatorObservers: [navigatorObserver],
      home: CreatePostScreen(httpClient: mockHttpClient),
    );
  }

  group('CreatePostScreen Widget Tests', () {
    testWidgets('Renders all UI elements correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      expect(find.text('Create Post'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Submit Post'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Shows error when submitting empty post', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      // Try to submit empty post
      await tester.tap(find.text('Submit Post'));
      await tester.pumpAndSettle();

      expect(find.text('Post content cannot be empty.'), findsOneWidget);
    });

    testWidgets('Successfully creates a post', (WidgetTester tester) async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('{"status": "success"}', 201));

      await tester.pumpWidget(createTestApp());

      // Enter post text
      await tester.enterText(find.byType(TextField), 'Test post content');
      await tester.pump();

      // Submit post
      await tester.tap(find.text('Submit Post'));
      await tester.pumpAndSettle();

      // Verify HTTP call
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);

      // Verify success message
      expect(find.text('Post created successfully.'), findsOneWidget);

      // Verify navigation
      verify(() => navigatorObserver.didPop(any(), any())).called(1);
    });

    testWidgets('Shows error on API failure', (WidgetTester tester) async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('{"error": "Server error"}', 500));

      await tester.pumpWidget(createTestApp());

      // Enter post text
      await tester.enterText(find.byType(TextField), 'Test post content');
      await tester.pump();

      // Submit post
      await tester.tap(find.text('Submit Post'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Server error'), findsOneWidget);
    });

    testWidgets('Character counter works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      // Enter some text
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pump();

      // Verify counter shows correct count
      expect(find.text('4/256'), findsOneWidget);
    });

    testWidgets('Back button works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      // Tap back button
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Verify navigation
      verify(() => navigatorObserver.didPop(any(), any())).called(1);
    });
  });
}