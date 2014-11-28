Feature: Composing Notes
	Scenario: Answering questions creates notes
        Given I am at the doctors
        When the doctor asks me "Where does it hurt?"
        And I answer "my left leg"
        And the doctor asks me "is it bleeding?"
        And I answer "yes"
        And the doctor asks me "is it aching?"
        And I answer "no"
        Then the doctor makes the following notes:
            """
                Complaint
                ---------
                Bleeding left leg
            """
