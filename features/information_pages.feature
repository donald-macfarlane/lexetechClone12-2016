Feature: Information Pages
  Scenario Outline: Seeing the information page
    When I go to the <page> page
    Then I can see the content <content>

    Examples:
      | page     | content  |
      | FAQ      | FAQ      |
      | tutorial | Tutorial |
      | contact  | Contact  |
