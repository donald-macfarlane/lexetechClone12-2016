Feature: Remember me
  Because people close their browsers
  We shouldn't make them re-enter credentials all the time

  Scenario: Log me in automatically after closing my browser
    Given I have logged in
    When I close my browser
    And I come back next time
    Then I should be logged in again
