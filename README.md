Strava board
=
Shows Strava activities feed as dashboard. Supports auto reload and filtering of athletes. 

Built with Elm front-end and Spring boot SSO to Strava API.

Config
===
* Set Strava App config (clientId and clientSecret) in src/resources/application.yml

Build:
=== 
* elm-make src/main/elm/Board/Main.elm --yes --output=target/classes/static/js/main.js --debug
* mvn install

Run:
===
* java -jar target/stravaboard.jar