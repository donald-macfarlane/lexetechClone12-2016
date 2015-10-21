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

  Scenario: A new user
    Given I am logged in as an admin
    When I create a new user "Jane Thompson" with email "jane@example.com"
    Then I can copy the signup link
    When that link is used by the new user
    Then they can set their password "password123" and login
    And I can start a new document
    When they have logged out
    Then can log back in with the same password "password123"

  Scenario: Forgot my password
    Given there is a user with email "jane@example.com" with password "something hard to remember"
    When she clicks on the forgot my password link
    And she enters her email address "jane@example.com"
    Then she receives an email with a reset password link
    When she clicks on the reset password link
    Then she can enter a new password "janessecret"
    Then she can start a new document
    Given she has logged out
    When she logs in with email address "jane@example.com" and password "janessecret"
    Then she can start a new document
