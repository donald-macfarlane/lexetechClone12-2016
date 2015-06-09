Feature: Composing Notes
  Background:
    Given there is a comprehensive lexicon
    And the doctor has an account
    And the doctor has signed in

  Scenario: Answering questions creates notes
    Given I am at the doctors
    And the doctor starts a new document
    When the doctor asks me "WHAT HURTS?"
    And I answer "left leg"
    And the doctor asks me "IS IT BLEEDING?"
    And I answer "yes"
    And the doctor asks me "IS IT ACHING?"
    And I answer "no"
    Then the doctor makes the following notes:
      """
      Complaint
      ---------
      left leg bleeding
      """
