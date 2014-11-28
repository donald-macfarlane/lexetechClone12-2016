Feature: Composing Notes
  Scenario: Answering questions creates notes
    Given I am at the doctors
    When the doctor asks me "What hurts?"
    And I answer "left leg"
    And the doctor asks me "Is it bleeding?"
    And I answer "yes"
    And the doctor asks me "Is it aching?"
    And I answer "no"
    Then the doctor makes the following notes:
      """
      Complaint
      ---------
      Bleeding left leg
      """
