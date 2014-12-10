Feature: Logging In
  Scenario: Creating a new user
    When I create a new user with email address "bob@example.com" and password "bobssecret"
    Then the doctor asks me "What hurts?"
