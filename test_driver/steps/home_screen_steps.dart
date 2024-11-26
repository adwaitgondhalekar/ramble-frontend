import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';
import 'package:flutter_driver/flutter_driver.dart';

StepDefinitionGeneric GivenIAmLoggedIn() {
  return given<FlutterWorld>('I am logged in', (context) async {
    await context.world.driver!.waitFor(find.byValueKey('loginScreen'));
    await context.world.driver!.tap(find.byValueKey('usernameField'));
    await context.world.driver!.enterText('test_user');
    await context.world.driver!.tap(find.byValueKey('passwordField'));
    await context.world.driver!.enterText('test_pass');
    await context.world.driver!.tap(find.byValueKey('loginButton'));
    await context.world.driver!.waitFor(find.byValueKey('homeScreen'));
  });
}

StepDefinitionGeneric WhenIPullToRefresh() {
  return when<FlutterWorld>('I pull to refresh', (context) async {
    await context.world.driver!.scroll(find.byValueKey('refreshIndicator'), 0, 300, const Duration(seconds: 1));
  });
}

StepDefinitionGeneric ThenIShouldSeeAListOfPosts() {
  return then<FlutterWorld>('I should see a list of posts', (context) async {
    final postCard = find.byValueKey('postCard_0'); // Check for the first post card
    await context.world.driver!.waitFor(postCard);
  });
}
