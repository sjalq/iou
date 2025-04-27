module Backend exposing (..)

import Auth.Flow
import Dict
-- import Fusion.Generated.Types
-- import Fusion.Patch
import Lamdera
import RPC
import Rights.Auth0 exposing (backendConfig)
import Rights.Permissions exposing (sessionCanPerformAction)
import Rights.Role exposing (roleToString)
import Rights.User exposing (createUser, getUserRole, insertUser, isSysAdmin)
import Supplemental exposing (..)
import Task exposing (Task)
import Types exposing (..)
import Debug -- Import Debug
import Time exposing (Posix)


type alias Model =
    BackendModel


app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontendCheckingRights
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub msg
subscriptions _ =
    Sub.batch
        [-- things that run on timers and things that listen to the outside world
        ]


init : ( Model, Cmd BackendMsg )
init =
    ( { logs = []
      , pendingAuths = Dict.empty
      , sessions = Dict.empty
      , users = Dict.empty
      , pollingJobs = Dict.empty
      , ious = Dict.empty
      }
    , Cmd.none
    )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        NoOpBackendMsg ->
            ( model, Cmd.none )

        Log logMsg ->
            ( model, Cmd.none )
                |> log logMsg

        GotRemoteModel result ->
            case result of
                Ok model_ ->
                    ( model_, Cmd.none )
                        |> log "GotRemoteModel Ok"

                Err err ->
                    ( model, Cmd.none )
                        |> log ("GotRemoteModel Err: " ++ httpErrorToString err)

        AuthBackendMsg authMsg ->
            Auth.Flow.backendUpdate (backendConfig model) authMsg

        GotCryptoPriceResult token result ->
            case result of
                Ok priceStr ->
                    let
                        updatedPollingJobs =
                            Dict.insert token (Ready (Ok priceStr)) model.pollingJobs
                    in
                    ( { model | pollingJobs = updatedPollingJobs }, Cmd.none )
                        |> log ("Crypto price calculated: " ++ priceStr)

                Err err ->
                    let
                        updatedPollingJobs =
                            Dict.insert token (Ready (Err (httpErrorToString err))) model.pollingJobs
                    in
                    ( { model | pollingJobs = updatedPollingJobs }, Cmd.none )
                        |> log ("Failed to calculate crypto price: " ++ httpErrorToString err)

        StoreTaskResult token result ->
            let
                updatedPollingJobs =
                    Dict.insert token (Ready result) model.pollingJobs
                
                logMsg =
                    case result of
                        Ok data ->
                            "Task completed successfully: " ++ token
                        
                        Err err ->
                            "Task failed: " ++ token ++ " - " ++ err
            in
            ( { model | pollingJobs = updatedPollingJobs }, Cmd.none )
                |> log logMsg

        GotJobTime token timestamp ->
            let
                updatedPollingJobs =
                    Dict.insert token (BusyWithTime timestamp) model.pollingJobs
            in
            ( { model | pollingJobs = updatedPollingJobs }, Cmd.none )
                |> log ("Updated job " ++ token ++ " with timestamp: " ++ String.fromInt timestamp)

        HandleCreatedIouResult connectionId result ->
            case result of
                Ok iouEntry ->
                    let
                        updatedModel =
                            { model | ious = Dict.insert iouEntry.id iouEntry model.ious }

                        -- Send the full list of IOUs for that user back
                        userIous =
                            Dict.filter (\_ iou -> iou.creatorId == iouEntry.creatorId) updatedModel.ious
                    in
                    ( updatedModel, Lamdera.sendToFrontend connectionId (IouSync userIous) )
                        |> log ("IOU created successfully: " ++ iouEntry.id)

                Err errorMsg ->
                    ( model, Lamdera.sendToFrontend connectionId (IouOpError ("Failed to create IOU: " ++ errorMsg)) )
                        |> log ("Failed to create IOU: " ++ errorMsg)


updateFromFrontend : BrowserCookie -> ConnectionId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend browserCookie connectionId msg model =
    case msg of
        NoOpToBackend ->
            ( model, Cmd.none )

        Admin_FetchLogs ->
            ( model, Lamdera.sendToFrontend connectionId (Admin_Logs_ToFrontend model.logs) )

        Admin_ClearLogs ->
            let
                newModel =
                    { model | logs = [] }
            in
            ( newModel, Lamdera.sendToFrontend connectionId (Admin_Logs_ToFrontend newModel.logs) )

        Admin_FetchRemoteModel remoteUrl ->
            ( model
              -- put your production model key in here to fetch from your prod env.
            , RPC.fetchImportedModel remoteUrl "1234567890"
                |> Task.attempt GotRemoteModel
            )

        AuthToBackend authToBackend ->
            Auth.Flow.updateFromFrontend (backendConfig model) connectionId browserCookie authToBackend model

        GetUserToBackend ->
            case Dict.get browserCookie model.sessions of
                Just userInfo ->
                    case getUserFromCookie browserCookie model of
                        Just user ->
                            ( model, Cmd.batch [ Lamdera.sendToFrontend connectionId <| UserInfoMsg <| Just userInfo, Lamdera.sendToFrontend connectionId <| UserDataToFrontend <| userToFrontend user ] )

                        Nothing ->
                            let
                                initialPreferences =
                                    { darkMode = True } -- Default new users to dark mode
                                
                                user =
                                    createUser userInfo initialPreferences

                                newModel =
                                    insertUser userInfo.email user model
                            in
                            ( newModel, Cmd.batch [ Lamdera.sendToFrontend connectionId <| UserInfoMsg <| Just userInfo, Lamdera.sendToFrontend connectionId <| UserDataToFrontend <| userToFrontend user ] )

                Nothing ->
                    ( model, Lamdera.sendToFrontend connectionId <| UserInfoMsg Nothing )

        LoggedOut ->
            ( { model | sessions = Dict.remove browserCookie model.sessions }, Cmd.none )

        SetDarkModePreference preference ->
            case getUserFromCookie browserCookie model of
                Just user ->
                    let
                        -- Explicitly alias the nested record
                        currentPreferences = 
                            user.preferences
                        
                        updatedUserPreferences : Preferences
                        updatedUserPreferences =
                            { currentPreferences | darkMode = preference } -- Update the alias
                        
                        updatedUser : User
                        updatedUser =
                            { user | preferences = updatedUserPreferences }

                        updatedUsers =
                            Dict.insert user.email updatedUser model.users
                    in
                    ( { model | users = updatedUsers }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )
                        |> log "User or session not found for SetDarkModePreference"

        -- Fusion_PersistPatch patch ->
        --     let
        --         value =
        --             Fusion.Patch.patch { force = False } patch (Fusion.Generated.Types.toValue_BackendModel model)
        --                 |> Result.withDefault (Fusion.Generated.Types.toValue_BackendModel model)
        --     in
        --     case
        --         Fusion.Generated.Types.build_BackendModel value
        --     of
        --         Ok newModel ->
        --             ( newModel
        --               -- , Lamdera.sendToFrontend connectionId (Admin_FusionResponse value)
        --             , Cmd.none
        --             )

                -- Err err ->
                --     ( model
                --     , Cmd.none
                --     )
                --         |> log ("Failed to apply fusion patch: " ++ Debug.toString err)

        -- Fusion_Query query ->
        --     ( model
        --     , Lamdera.sendToFrontend connectionId (Admin_FusionResponse (Fusion.Generated.Types.toValue_BackendModel model))
        --     )

        --- IOU Msgs
        FetchIous ->
            Debug.todo "Implement FetchIous"

        CreateIou iouData ->
            case getUserFromCookie browserCookie model of
                Just user ->
                    let
                        createTask : Task Never (Result String IouEntry)
                        createTask =
                            Time.now
                                |> Task.map (\time ->
                                    let
                                        -- Create a simple ID using timestamp and user email
                                        newId =
                                            user.email ++ "@" ++ String.fromInt (Time.posixToMillis time)
                                    in
                                    Ok { id = newId
                                       , creatorId = user.email
                                       , otherPartyId = iouData.otherPartyId
                                       , amount = iouData.amount
                                       , description = iouData.description
                                       , createdAt = time
                                       , direction = iouData.direction
                                       }
                                )
                                |> Task.onError (\_ -> Task.succeed (Err "Failed to get time")) -- Map error to Ok (Err ...)
                    in
                    ( model, Task.perform (HandleCreatedIouResult connectionId) createTask )
                
                Nothing ->
                     ( model, Lamdera.sendToFrontend connectionId (IouOpError "User not logged in or found") )
                         |> log "CreateIou failed: User not found for cookie."

        DeleteIou _ ->
            Debug.todo "Implement DeleteIou"

        UpdateNewIou _ -> -- Add placeholder
            Debug.todo "Implement UpdateNewIou"


updateFromFrontendCheckingRights : BrowserCookie -> ConnectionId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontendCheckingRights browserCookie connectionId msg model =
    if
        case msg of
            NoOpToBackend ->
                True

            LoggedOut ->
                True

            AuthToBackend _ ->
                True

            GetUserToBackend ->
                True
            
            SetDarkModePreference _ -> -- Allow everyone to set their own preference
                True

            _ ->
                sessionCanPerformAction model browserCookie msg
    then
        updateFromFrontend browserCookie connectionId msg model

    else
        ( model, Lamdera.sendToFrontend connectionId (PermissionDenied msg) )


getUserFromCookie : BrowserCookie -> Model -> Maybe User
getUserFromCookie browserCookie model =
    Dict.get browserCookie model.sessions
        |> Maybe.andThen (\userInfo -> Dict.get userInfo.email model.users)


log =
    Supplemental.log NoOpBackendMsg


userToFrontend : User -> UserFrontend
userToFrontend user =
    { email = user.email
    , isSysAdmin = isSysAdmin user
    , role = getUserRole user |> roleToString
    , preferences = user.preferences
    }
