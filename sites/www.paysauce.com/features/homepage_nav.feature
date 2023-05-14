Feature: Homepage navigation
  Can we load the different site sections?

  Scenario Outline: Using top nav links
    Given I'm on the homepage
    When I navigate to "<page>"
    Then the first H1 on the page should be "<heading>"

  Examples:
    | page    | heading  |
    | pricing | Pricing  |
    | blog    | Blog     |

