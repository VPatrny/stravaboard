module Board.Main exposing (..)

import Board.Activity exposing (Activity, Athlete, decodeActivity, decodeActivities)
import Board.Auth as Auth
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import String exposing (append)
import Date exposing (Date, fromString)
import Http
import Task
import Set exposing (Set)
import List.Extra
import Time exposing (Time)

main =
  Html.program { init = init, view = view, update = update, subscriptions = subscriptions }


-- MODEL

type alias Model =
    { activities : List Activity
    , athlete_names : List AthleteName
    , hidden_athlete_ids : Set Int
    , message : Maybe String
    , config : Config
    }

type alias AthleteName =
    { id : Int
    , name : String
    }

type alias Config =
    { layout_columns : Int
    , number_of_activities : Int
    , auth_token: Maybe String
    , auto_reload_minutes : Int
    }

init : ( Model, Cmd Msg )
init =
    let
        model : Model
        model = Model [] [] Set.empty ( Just "Logging in" ) ( Config 4 20 Nothing 15 )
    in
        ( model
        , loadToken model.config
        )

loadToken : Config -> Cmd Msg
loadToken config =
        Http.send UpdateToken (Auth.getString "/token")

loadActivities : Config -> Cmd Msg
loadActivities config =
        let
            url = "https://www.strava.com/api/v3/activities/following?per_page=" ++ toString config.number_of_activities
        in
            Http.send UpdateActivities (Auth.getAuth url (Maybe.withDefault "" config.auth_token) decodeActivities)

-- UPDATE

type Msg
    = UpdateToken (Result Http.Error (String))
    | UpdateActivities (Result Http.Error (List (Activity)))
    | FilterAthlete Int
    | OnInputNumOfActivities String
    | OnInputReloadMinutes String
    | ReloadActivities
    | AutoReloadActivities Time

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    UpdateToken (Ok new_token) ->
        let
            new_model : Model
            new_model = { model
                        | activities = []
                        , athlete_names = []
                        , message = Just "Loading activities"
                        , config = (updateAuthToken new_token model.config)
                        }
        in
            ( new_model
            , loadActivities new_model.config )

    UpdateToken (Err _) ->
        ( { model
            | activities = []
            , athlete_names = []
            , message = Just "Strava authentication token not found"
            }
            , Cmd.none )

    UpdateActivities (Ok activities) ->
        ( { model
            | activities = activities
            , athlete_names = getAthleteNames activities
            , message = Nothing
            }
            , Cmd.none )

    UpdateActivities (Err _) ->
        ( { model
            | activities = []
            , athlete_names = []
            , message = Just "Error loading activities"
            }
            , Cmd.none )

    FilterAthlete athlete_id ->
        ( { model
            | hidden_athlete_ids = (switchIdInSet athlete_id model.hidden_athlete_ids)
            }
            , Cmd.none )

    OnInputNumOfActivities value ->
        ( { model
            | config = (updateNumOfActivities value model.config)
            }, Cmd.none
        )

    OnInputReloadMinutes value ->
        ( { model
            | config = (updateAutoReloadMinutes value model.config)
            }, Cmd.none
        )

    ReloadActivities ->
        (model, loadActivities model.config)

    AutoReloadActivities time ->
        (model, loadActivities model.config)


updateAuthToken : String -> Config -> Config
updateAuthToken new_token config =
    { config | auth_token = Just new_token }

updateNumOfActivities : String -> Config -> Config
updateNumOfActivities value config =
    { config | number_of_activities = Result.withDefault 20 (String.toInt value) }

updateAutoReloadMinutes : String -> Config -> Config
updateAutoReloadMinutes value config =
    { config | auto_reload_minutes = Result.withDefault 15 (String.toInt value) }

getAthleteNames : List Activity -> List AthleteName
getAthleteNames activities =
    List.sortBy .name
        <| List.Extra.uniqueBy .id
        <| List.map getAthleteName activities

getAthleteName : Activity -> AthleteName
getAthleteName activity =
    AthleteName activity.athlete.id (activity.athlete.firstname ++ " " ++ activity.athlete.lastname)

switchIdInSet : Int -> Set Int -> Set Int
switchIdInSet id set_ids =
    if Set.member id set_ids then Set.remove id set_ids
    else Set.insert id set_ids

-- VIEW

view : Model -> Html Msg
view model =
    div [] [
        viewNavBar model
        , viewMessage model.message
        , div [] (viewActivities model )
    ]

viewNavBar : Model -> Html Msg
viewNavBar model =
    div [ class "row" ] [
        div [ class "col-md-6" ] [ a [ href "http://www.strava.com" ] [ img [ src "images/api_logo_pwrdBy_strava_horiz_light.png", alt "Powered by Strava" ] [] ] ],
        div [ class "col-md-6" ] [ viewFilterAthletes model ]
    ]

viewFilterAthletes : Model -> Html Msg
viewFilterAthletes model =
    div [ class "dropdown pull-right" ] [
            button [ attribute "type" "button", class "btn btn-default btn-sm dropdown-toggle", attribute "data-toggle" "dropdown" ] [
                viewIcon "fa fa-cog"
            ],
            ul [ class "dropdown-menu" ]
                [
                div [ class "input-group input-group-sm" ] [
                    span [ class "input-group-addon" ] [ text "Activities #" ]
                    , input [ attribute "type" "text", class "form-control", value (toString model.config.number_of_activities), onInput OnInputNumOfActivities ] []
                ]
                , div [ class "input-group input-group-sm" ] [
                    span [ class "input-group-addon" ] [ text "Reload minutes" ]
                    , input [ attribute "type" "text", class "form-control", value (toString model.config.auto_reload_minutes), onInput OnInputReloadMinutes ] []
                ]
                , button [ onClick ReloadActivities ] [ text "Reload" ]
                , li [ attribute "role" "separator", class "divider" ] []
                , li [ class "dropdown-header" ] [ text "Athletes" ]
                , div [] (List.map (viewFilterAthlete model) model.athlete_names)
                ]
        ]

viewFilterAthlete : Model -> AthleteName -> Html Msg
viewFilterAthlete model athlete =
    li [] [
        input [ attribute "type" "checkbox"
            , onClick (FilterAthlete athlete.id)
            , checked (not (Set.member athlete.id model.hidden_athlete_ids))
            ] []
        , text (athlete.name)
    ]

viewMessage : Maybe String -> Html Msg
viewMessage  message=
    case message of
        Nothing ->
            div [] []
        Just value ->
            div [] [ text ("Message: " ++ value) ]


viewActivities : Model -> List (Html Msg)
viewActivities model =
    List.map viewActivitiesRow
        <| split model.config.layout_columns
        <| (List.filter (athleteNotHidden model) model.activities)

athleteNotHidden : Model -> Activity -> Bool
athleteNotHidden model activity =
    not
        <| Set.member activity.athlete.id model.hidden_athlete_ids

split : Int -> List a -> List (List a)
split i list =
  case List.take i list of
    [] -> []
    listHead -> listHead :: split i (List.drop i list)


viewActivitiesRow : List (Activity) -> Html Msg
viewActivitiesRow activities =
    div [ class "row" ] (List.map viewActivity activities)


viewActivity : Activity -> Html Msg
viewActivity activity =
    div [ class "col-md-3 activity" ] [
        viewAvatar activity
        , div [] [
            div [] [ text (activity.athlete.firstname ++ " " ++ activity.athlete.lastname) ]
            , div [ class "grey" ] [text (valueDate activity.start_date) ]
            , h3 [] [
                span [] [ viewActivityType activity ]
                , text " "
                , strong [] [ text activity.name]
            ]
            , ul [ class "inline grey" ] [
                valueCommute activity.commute
                , li [] [ text (valueKm activity.distance) ]
                , li [] [ text (valueMeters activity.total_elevation_gain) ]
                , li [] [ text (valueAverageSpeedKmh activity.average_speed) ]
                , viewAchievements activity
            ]
            , viewKudosComments activity
        ]
    ]

viewAvatar : Activity -> Html Msg
viewAvatar activity =
    div [ class "avatar" ] [
        img [ class "round_avatar", src (valueAthleteProfileURL activity.athlete.profile) ] []
    ]

valueAthleteProfileURL : String -> String
valueAthleteProfileURL profile =
    if profile == "Unknown" || profile == "avatar/athlete/medium.png" then "images/avatar.png"
    else profile

valueDate : String -> String
valueDate value =
    case (Date.fromString value) of
        Err msg ->
            value

        Ok date ->
             formatDate date

formatDate : Date -> String
formatDate date =
    toString (Date.month date) ++ " " ++ toString (Date.day date) ++ ", " ++ toString (Date.year date) ++ " at " ++ toString (Date.hour date) ++ ":" ++ toString (Date.minute date)

viewActivityType : Activity -> Html Msg
viewActivityType activity =
    viewIcon (valueActivityTypeIcon activity.activity_type)

viewIcon : String -> Html Msg
viewIcon iconClass =
    i [ class iconClass, attribute "aria-hidden" "true"] []

valueActivityTypeIcon : String -> String
valueActivityTypeIcon value =
    if value == "Ride" then "fa fa-bicycle"
    else if value == "Run" || value == "Walk" then "fa fa-male"
    else if value == "BackcountrySki" then "fa fa-snowflake-o"
    else if value == "Swim" then "fa fa-shower"
    else "fa fa-plane"

valueCommute : Bool -> Html msg
valueCommute value =
    if value then li [] [ span [ class "badge"] [ text "commute" ] ]
    else li [] []

valueKm : Float -> String
valueKm meters =
    toString(toFloat(round (meters/100))/10) ++ "km"

valueMeters : Float -> String
valueMeters meters =
    toString(round(meters)) ++ "m"

valueAverageSpeedKmh : Float -> String
valueAverageSpeedKmh average_speed =
    toString(toFloat (round (average_speed * 36.0)) / 10) ++ "km/h"

viewAchievements : Activity -> Html Msg
viewAchievements activity =
    let
        achievement_count = activity.achievement_count
    in
        if achievement_count == 0 then li [] [ text "" ]
        else li [] [ viewIcon "fa fa-trophy", text (" " ++ toString activity.achievement_count) ]

viewKudosComments : Activity -> Html Msg
viewKudosComments activity =
    div [ class "btn-group social btn-group-sm", attribute "role" "group" ] [
        button [ attribute "type" "button", class "btn btn-default" ] [
            viewIcon "fa fa-thumbs-o-up"
            , text (valueNumberOrEmpty activity.kudos_count)
        ]
        , button [ attribute "type" "button", class "btn btn-default" ] [
            viewIcon "fa fa-comment-o"
            , text (valueNumberOrEmpty activity.comment_count)
        ]
    ]

valueNumberOrEmpty : Int -> String
valueNumberOrEmpty value =
    if value == 0 then " "
    else " " ++ toString(value)


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
      Time.every (Time.minute * toFloat model.config.auto_reload_minutes) AutoReloadActivities