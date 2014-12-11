Feature: Password reminder
  Because people are forgetful
  We allow them to reset their password

  Scenario: Reset password
    Given I have an account
    When I ask for a password reminder
    Then I am sent an email with a link in it
    When I follow the link in the email
    Then I can reset my password
