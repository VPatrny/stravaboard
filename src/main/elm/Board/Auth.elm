module Board.Auth exposing (getAuth, getString)

import Http exposing ( Request, header, request, emptyBody, expectJson )
import Json.Decode as Decode

getAuth : String -> String -> Decode.Decoder a -> Request a
getAuth url auth_token decoder =
    request
        { method = "GET"
        , headers = [ header "Authorization" ("Bearer " ++ auth_token) ]
        , url = url
        , body = emptyBody
        , expect = expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }

getString : String -> Request String
getString url =
    Http.getString url