Feature: Authentication
  Background:
    Given there are some queries

  Scenario: Creating a new user
    When I create a new user with email address "bob@example.com" and password "bobssecret"
    Then I can start a new document

  Scenario: Logging in
    Given I have created a user previously with email address "bob@example.com" and password "bobssecret"
    And I have logged out
    When I log in with email address "bob@example.com" and password "bobssecret"
    Then I can start a new document
