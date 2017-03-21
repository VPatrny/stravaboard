Strava board
=
Shows Strava activities feed as dashboard. Supports auto reload and filtering of athletes. 

Built with Elm front-end and Spring boot SSO to Strava API.

Build:
* elm-make src/main/elm/Board/Main.elm --output=src/main/resources/static/js/main.js
* configure Strava App in application.yml (clientId and clientSecret)  
* mvn clean install