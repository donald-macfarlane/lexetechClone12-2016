@wip
Feature: Authoring
  To keep the system useful in new and changing domains
  Authors must edit and update queries and responses

  Scenario: Create block
    Given there are no blocks
    When I create the block "Haematology"
    Then I should arrive at the block

  Scenario: Add query to block
    Given the block "Haematology" exists
    When I add the query "HPI:ChestPain Pain radiation"
    Then I can add responses to the query

  Scenario: Add responses to query
    Given the block "Haematology" exists
    And the query "HPI:ChestPain Pain radiation" exists
    When I add the response "Neck and shoulder"
    Then I can compose notes about Heamatology