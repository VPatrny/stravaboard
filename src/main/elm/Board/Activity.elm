module Board.Activity exposing (Activity, Athlete, decodeActivity, decodeActivities )

import Json.Decode exposing (Decoder, list, string, int, float, bool)
import Json.Decode.Pipeline exposing (decode, required, optional)

type alias Activity =
    { id : Int
    , athlete : Athlete
    , name : String
    , distance : Float
    , moving_time : Int
    , elapsed_time : Int
    , total_elevation_gain : Float
    , activity_type : String
    , start_date : String
    , start_date_local : String
    , timezone : String
    , utc_offset : Int
    , location_city : String
    , location_state : String
    , location_country : String
    , achievement_count : Int
    , kudos_count : Int
    , comment_count : Int
    , commute : Bool
    , average_speed : Float
    , max_speed : Float
    , elev_high : Float
    , elev_low : Float
    }

type alias Athlete =
    { id : Int
    , firstname : String
    , lastname : String
    , city : String
    , country : String
    , profile : String
    }

decodeActivities : Decoder (List Activity)
decodeActivities = list decodeActivity

decodeActivity : Decoder Activity
decodeActivity =
    decode Activity
        |> optional "id" int -1
        |> required "athlete" decodeAthlete
        |> optional "name" string "Name"
        |> optional "distance" float 0.0
        |> optional "moving_time" int 0
        |> optional "elapsed_time" int 0
        |> optional "total_elevation_gain" float 0.0
        |> optional "type" string "ride"
        |> optional "start_date" string "Unknown"
        |> optional "start_date_local" string "Unknown"
        |> optional "timezone" string "Unknown"
        |> optional "utc_offset" int 0
        |> optional "location_city" string "Unknown"
        |> optional "location_state" string "Unknown"
        |> optional "location_country" string "Unknown"
        |> optional "achievement_count" int 0
        |> optional "kudos_count" int 0
        |> optional "comment_count" int 0
        |> optional "commute" bool False
        |> optional "average_speed" float 0.0
        |> optional "max_speed" float 0.0
        |> optional "elev_high" float 0.0
        |> optional "elev_low" float 0.0


decodeAthlete : Decoder Athlete
decodeAthlete =
    decode Athlete
        |> optional "id" int -1
        |> optional "firstname" string "Unknown"
        |> optional "lastname" string "Unknown"
        |> optional "city" string "Unknown"
        |> optional "country" string "Unknown"
        |> optional "profile_medium" string "Unknown"