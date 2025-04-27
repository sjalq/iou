module Route exposing (..)

import Types exposing (AdminRoute(..), Route(..), UserId)
import Url exposing (Url, percentEncode)
import Url.Builder
import Url.Parser as Parser exposing ((</>), (<?>), Parser, custom, int, oneOf, s, string, query)
import Url.Parser.Query
import Debug


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Default Parser.top
        , Parser.map (Admin AdminDefault) (s "admin")
        , Parser.map (Admin AdminLogs) (s "admin" </> s "logs")
        , Parser.map (Admin AdminFetchModel) (s "admin" </> s "fetch-model")
        --, Parser.map (Admin AdminFusion) (s "admin" </> s "fusion")
        , Parser.map IouHistory (s "iou" <?> Url.Parser.Query.string "other")
        ]


fromUrl : Url -> Route
fromUrl url =
    let
        parsedRoute =
            Parser.parse parser url
                |> Maybe.withDefault NotFound
        
        -- Log the final resolved route
        _ = 
            Debug.log ("Resolved route for " ++ Url.toString url ++ ": ") parsedRoute
    in
    parsedRoute


title : Route -> String
title route =
    case route of
        Default ->
            "IOU App - Home"

        Admin AdminDefault ->
            "IOU App - Admin"

        Admin AdminLogs ->
            "IOU App - Admin Logs"

        Admin AdminFetchModel ->
            "IOU App - Admin Fetch Model"

        IouHistory maybeOtherUser ->
            case maybeOtherUser of
                Just otherUser ->
                    "IOU History with " ++ otherUser
                Nothing -> 
                    "IOU History - Invalid User"

        NotFound ->
            "IOU App - Not Found"


toString : Route -> String
toString route =
    case route of
        Default ->
            "/"

        Admin AdminDefault ->
            "/admin"

        Admin AdminLogs ->
            "/admin/logs"

        Admin AdminFetchModel ->
            "/admin/fetch-model"

        -- Admin AdminFusion ->
        --     "/admin/fusion"

        IouHistory maybeOtherUser ->
            case maybeOtherUser of
                Just otherUser ->
                    Url.Builder.crossOrigin "" 
                        [ "iou" ]
                        [ Url.Builder.string "other" otherUser ]
                Nothing -> -- Should ideally not be navigated to directly
                    "/iou" 

        NotFound ->
            "/not-found"
