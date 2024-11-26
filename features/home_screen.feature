Feature: Home Screen

  Scenario: Load posts on the home screen
    Given I am logged in
    Then I should see a list of posts

  Scenario: Refresh posts on the home screen
    Given I am logged in
    When I pull to refresh
    Then I should see a list of posts
