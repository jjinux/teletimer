Feature: Twilio
So that I can time my wife's contractions
As a user
I want to call a phone number and have it time her contractions

Scenario: call the service
  When I call the service
  Then I should get a valid TwiML response
  And it should say "Welcome to Teletimer."

  When I follow the redirect
  Then I should get a valid TwiML response
  And it should say "Press any key when the contraction starts."

  When I enter "1"
  Then I should get a valid TwiML response
  And it should say "Press any key when the contraction stops."

  When I enter "1" after 240 seconds
  Then I should get a valid TwiML response
  And it should say "The contraction lasted 4 minutes."

  When I follow the redirect
  Then I should get a valid TwiML response
  And it should say "Press any key when the contraction starts."