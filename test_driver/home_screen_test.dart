import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';
import 'steps/home_screen_steps.dart';

Future<void> main() async {
  final config = FlutterTestConfiguration()
    ..features = ['features/home_screen.feature']
    ..stepDefinitions = [
      GivenIAmLoggedIn(),
      WhenIPullToRefresh(),
      ThenIShouldSeeAListOfPosts(),
    ]
    ..restartAppBetweenScenarios = true
    ..targetAppPath = "test_driver/app.dart";

  await GherkinRunner().execute(config);
}
