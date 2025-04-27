module Frontend exposing (..)

import Auth.Common
import Auth.Flow
import Browser exposing (UrlRequest(..), Document)
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes as Attr exposing (style)
import Html.Events as HE
import Lamdera
import Pages.Admin
import Pages.Default
import Pages.PageFrame
import Pages.UserIouHistory
import Route exposing (..)
import Supplemental exposing (..)
import Time exposing (..)
import Types exposing (..)
import Url exposing (Url)
import Theme
import Dict exposing (Dict)
import Debug
-- import Random
-- import Fusion.Patch
-- import Fusion

type alias Model =
    FrontendModel



-- app =
--     Lamdera.frontend
--         { init = initWithAuth
--         , onUrlRequest = UrlClicked
--         , onUrlChange = UrlChanged
--         , update = update
--         , updateFromBackend = updateFromBackend
--         , subscriptions = subscriptions
--         , view = view
--         }


{-| replace with your app function to try it out
-}
app =
    Lamdera.frontend
        { init = initWithAuth
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = always Sub.none
        , view = view
        }


subscriptions : FrontendModel -> Sub FrontendMsg
subscriptions _ =
    Sub.none


-- Define mock user IDs
currentUserEmail : UserId
currentUserEmail = "schalk.dormehl@gmail.com" -- Updated for mock data

otherUserEmail : UserId
otherUserEmail = "them@example.com"

sakeligaUserEmail : UserId -- Added for new mock data
sakeligaUserEmail = "s.dormehl@sakeliga.org.za"

-- Create mock IOUs
mockIous : List IouEntry
mockIous =
    [ { id = "iou1"
      , creatorId = currentUserEmail
      , otherPartyId = otherUserEmail
      , amount = 50.0
      , description = "Lunch"
      , createdAt = Time.millisToPosix (1678886400000) -- March 15, 2023
      , direction = Lent -- I lent to them
      }
    , { id = "iou2"
      , creatorId = otherUserEmail
      , otherPartyId = currentUserEmail
      , amount = 20.0
      , description = "Coffee"
      , createdAt = Time.millisToPosix (1679318400000) -- March 20, 2023
      , direction = Lent -- They lent to me
      }
     , { id = "iou3"
      , creatorId = currentUserEmail
      , otherPartyId = otherUserEmail
      , amount = 100.0
      , description = "Tickets"
      , createdAt = Time.millisToPosix (1681564800000) -- April 15, 2023
      , direction = Borrowed -- I borrowed from them
      }
    , { id = "iou4"
      , creatorId = otherUserEmail
      , otherPartyId = currentUserEmail
      , amount = 30.0
      , description = "Snacks"
      , createdAt = Time.millisToPosix (1681996800000) -- April 20, 2023
      , direction = Borrowed -- They borrowed from me
      }
    , { id = "iou5"
      , creatorId = currentUserEmail
      , otherPartyId = "another@example.com" -- Interaction with a different user
      , amount = 10.0
      , description = "Irrelevant"
      , createdAt = Time.millisToPosix (1681996800000) -- April 20, 2023
      , direction = Lent
      }
    , { id = "iou6"
      , creatorId = currentUserEmail
      , otherPartyId = sakeligaUserEmail 
      , amount = 250.0
      , description = "Consulting Work"
      , createdAt = Time.millisToPosix (1704067200000) -- Jan 1, 2024
      , direction = Lent -- I lent (provided service)
      }
    , { id = "iou7"
      , creatorId = sakeligaUserEmail
      , otherPartyId = currentUserEmail
      , amount = 75.50
      , description = "Software License"
      , createdAt = Time.millisToPosix (1706745600000) -- Feb 1, 2024
      , direction = Lent -- They lent (paid for license I use)
      }
    ]

mockIouDict : Dict IouId IouEntry
mockIouDict =
    mockIous
        |> List.map (\iou -> (iou.id, iou))
        |> Dict.fromList


init : Url -> Nav.Key -> ( FrontendModel, Cmd FrontendMsg )
init url key =
    let
        route =
            Route.fromUrl url
        
        initialPreferences =
            { darkMode = True }

        initialNewIouInput : NewIouInput
        initialNewIouInput =
            { otherPartyId = ""
            , amount = ""
            , description = ""
            , direction = Lent -- Default direction
            }

        -- Mock current user for testing history page
        -- mockCurrentUser : UserFrontend
        -- mockCurrentUser =
        --      { email = currentUserEmail
        --      , isSysAdmin = False
        --      , role = "UserRole"
        --      , preferences = initialPreferences
        --      }

        model =
            { key = key
            , currentRoute = route
            , adminPage =
                { logs = []
                , isAuthenticated = False
                , remoteUrl = ""
                }
            , authFlow = Auth.Common.Idle
            , authRedirectBaseUrl = { url | query = Nothing, fragment = Nothing }
            , login = NotLogged False -- Reverted
            , currentUser = Nothing -- Reverted
            , pendingAuth = False
            , preferences = initialPreferences
            , ious = mockIouDict
            , iouError = Nothing
            , isLoadingIous = False
            , newIouInput = initialNewIouInput
            }
    in
    inits model route


inits : Model -> Route -> ( Model, Cmd FrontendMsg )
inits model route =
    case route of
        Admin adminRoute ->
            Pages.Admin.init model adminRoute

        Default ->
            Pages.Default.init model

        _ -> -- Handles IouHistory, NotFound implicitly by doing nothing extra on init
            ( model, Cmd.none )


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        NoOpFrontendMsg ->
            ( model, Cmd.none )

        UrlRequested urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        UrlChanged url ->
            let
                newModel =
                    { model | currentRoute = Route.fromUrl url }
            in
            inits newModel newModel.currentRoute

        DirectToBackend msg_ ->
            ( model, Lamdera.sendToBackend msg_ )

        Admin_RemoteUrlChanged url ->
            let
                oldAdminPage =
                    model.adminPage
            in
            ( { model | adminPage = { oldAdminPage | remoteUrl = url } }, Cmd.none )

        GoogleSigninRequested ->
            Auth.Flow.signInRequested "OAuthGoogle" { model | login = NotLogged True, pendingAuth = True } Nothing
                |> Tuple.mapSecond (AuthToBackend >> Lamdera.sendToBackend)

        Logout ->
            ( { model | login = NotLogged False, pendingAuth = False, preferences = { darkMode = False } }, Lamdera.sendToBackend LoggedOut )

        Auth0SigninRequested ->
            Auth.Flow.signInRequested "OAuthAuth0" { model | login = NotLogged True, pendingAuth = True } Nothing
                |> Tuple.mapSecond (AuthToBackend >> Lamdera.sendToBackend)

        ToggleDarkMode ->
            let
                newDarkModeState =
                    not model.preferences.darkMode

                -- Explicitly alias the nested record
                currentFrontendPreferences =
                    model.preferences

                updatedFrontendPreferences : Preferences
                updatedFrontendPreferences =
                    { currentFrontendPreferences | darkMode = newDarkModeState } -- Update the alias
            in
            ( { model | preferences = updatedFrontendPreferences }
            , Lamdera.sendToBackend (SetDarkModePreference newDarkModeState)
            )

        -- Admin_FusionPatch patch ->
        --     ( { model
        --         | fusionState =
        --             Fusion.Patch.patch { force = False } patch model.fusionState
        --                 |> Result.withDefault model.fusionState
        --       }
        --     , Lamdera.sendToBackend (Fusion_PersistPatch patch)
        --     )

        -- Admin_FusionQuery query ->
        --     ( model, Lamdera.sendToBackend (Fusion_Query query) )

        --- IOU Msgs
        GotIouUpdate iouDict ->
            ( { model | ious = iouDict, isLoadingIous = False, iouError = Nothing }, Cmd.none )

        IouOpFailed errorMsg ->
            ( { model | iouError = Just errorMsg, isLoadingIous = False }, Cmd.none )

        DeleteIouRequest iouId ->
            ( model, Lamdera.sendToBackend (DeleteIou iouId) )

        CreateIouRequest iouData ->
            ( model, Lamdera.sendToBackend (CreateIou iouData) )

        -- IOU INPUT HANDLING --
        UpdateNewIouDescription description ->
            let
                oldInput = model.newIouInput
            in
            ( { model | newIouInput = { oldInput | description = description } }, Cmd.none )

        UpdateNewIouAmount amountStr ->
            let
                oldInput = model.newIouInput
            in
            ( { model | newIouInput = { oldInput | amount = amountStr } }, Cmd.none )

        UpdateNewIouDirection direction ->
            let
                oldInput = model.newIouInput
            in
            ( { model | newIouInput = { oldInput | direction = direction } }, Cmd.none )

        UpdateNewIouOtherParty otherPartyId ->
            let
                oldInput = model.newIouInput
            in
            ( { model | newIouInput = { oldInput | otherPartyId = otherPartyId } }, Cmd.none )

        SubmitNewIou ->
            case String.toFloat model.newIouInput.amount of
                Just amountFloat ->
                    let
                        iouEntryData : IouEntryData
                        iouEntryData =
                            { otherPartyId = model.newIouInput.otherPartyId
                            , amount = amountFloat
                            , description = model.newIouInput.description
                            , direction = model.newIouInput.direction
                            }

                        -- Clear the form after attempting submission
                        clearedInput : NewIouInput
                        clearedInput =
                             { otherPartyId = ""
                             , amount = ""
                             , description = ""
                             , direction = Lent -- Reset to default
                             }

                        updatedModel =
                            { model | newIouInput = clearedInput, iouError = Nothing }

                    in
                    ( updatedModel, Lamdera.sendToBackend (CreateIou iouEntryData) )

                Nothing ->
                    -- Handle invalid amount input
                    ( { model | iouError = Just "Invalid amount entered. Please enter a number." }, Cmd.none )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        NoOpToFrontend ->
            ( model, Cmd.none )

        -- Admin page
        Admin_Logs_ToFrontend logs ->
            let
                oldAdminPage =
                    model.adminPage
            in
            ( { model | adminPage = { oldAdminPage | logs = logs } }, Cmd.none )

        AuthToFrontend authToFrontendMsg ->
            authUpdateFromBackend authToFrontendMsg model

        AuthSuccess userInfo ->
            -- Reverted: Always navigate to home and fetch user info
            ( { model | login = LoggedIn userInfo, pendingAuth = False }
            , Cmd.batch [ Nav.pushUrl model.key "/", Lamdera.sendToBackend GetUserToBackend ]
            )

        UserInfoMsg mUserinfo ->
            case mUserinfo of
                Just userInfo ->
                    ( { model | login = LoggedIn userInfo, pendingAuth = False }, Cmd.none )

                Nothing ->
                    ( { model | login = NotLogged False, pendingAuth = False, preferences = { darkMode = False } }, Cmd.none )

        UserDataToFrontend currentUser ->
            ( { model | currentUser = Just currentUser, preferences = currentUser.preferences }, Cmd.none )

        -- Admin_FusionResponse value ->
        --     ( { model | fusionState = value }, Cmd.none )

        PermissionDenied _ ->
            -- Simply ignore the denied action without any UI notification
            ( model, Cmd.none )

        --- IOU Msgs
        IouSync iouDict ->
            ( { model | ious = iouDict, iouError = Nothing, isLoadingIous = False }, Cmd.none )

        IouDeletedSuccessfully iouId ->
            ( { model | ious = Dict.remove iouId model.ious }, Cmd.none )

        IouOpError errorMsg ->
             ( { model | iouError = Just errorMsg, isLoadingIous = False }, Cmd.none )


view : Model -> Document FrontendMsg
view model =
    let
        isDark = model.preferences.darkMode
        colors = Theme.getColors isDark
        themeClass =
            if isDark then "dark" else ""

        -- Determine the main content based on the route
        viewContent =
            div [ Attr.class "flex-grow container mx-auto p-4" ] -- Container and padding moved here
                [ case model.currentRoute of
                    Admin adminRoute ->
                        Pages.Admin.view model colors 

                    Default ->
                        Pages.Default.view model colors
                    
                    IouHistory maybeOtherUserId -> -- Logic moved here
                        case ( model.currentUser, maybeOtherUserId ) of
                            ( Just _, Just _ ) -> -- Check if user logged in and ID exists
                                Pages.UserIouHistory.view model -- Pass the whole model
                            
                            ( Nothing, _ ) -> -- User not logged in
                                div [ Attr.class "text-center p-4", Attr.style "color" colors.primaryText ]
                                    [ h2 [ Attr.class "text-xl font-semibold" ] [ text "Login Required" ]
                                    , p [] [ text "Please log in to view your IOU history." ]
                                      -- Optionally add a login button here
                                    , button
                                        [ HE.onClick Auth0SigninRequested -- Assuming Auth0 is the primary login
                                        , Attr.class "mt-4 px-4 py-2 rounded"
                                        , Attr.style "background-color" colors.buttonBg
                                        , Attr.style "color" colors.buttonText
                                        ]
                                        [ text "Login" ]
                                    ]

                            ( _, Nothing ) -> -- otherUserId is missing from URL
                                div [ Attr.class "text-center p-4", Attr.style "color" colors.primaryText ]
                                    [ h2 [ Attr.class "text-xl font-semibold" ] [ text "Invalid User" ]
                                    , p [] [ text "Could not determine the user for the IOU history." ]
                                    ]

                    NotFound -> -- Logic moved here
                        div [ Attr.class "text-center p-4", Attr.style "color" colors.primaryText ]
                            [ h1 [ Attr.class "text-2xl font-bold" ] [ text "404 - Page Not Found" ]
                            , p [] [ text "The page you requested could not be found." ]
                            ]      
                ]

        -- Assemble the overall page structure using PageFrame components
        viewFrame =
            div [ Attr.class themeClass ]
                [ div [ Attr.class "min-h-screen flex flex-col", Attr.style "background-color" colors.primaryBg ]
                    [ Pages.PageFrame.viewHeader model -- Use header from PageFrame
                    , viewContent -- Inject the content determined above
                    , Pages.PageFrame.viewFooter model -- Use footer from PageFrame
                    ]
                ]
    in
    { title = Route.title model.currentRoute
    , body = [ viewFrame ]
    }


callbackForAuth0Auth : FrontendModel -> Url.Url -> Nav.Key -> ( FrontendModel, Cmd FrontendMsg )
callbackForAuth0Auth model url key =
    let
        ( authM, authCmd ) =
            Auth.Flow.init model
                "OAuthAuth0"
                url
                key
                (\msg -> Lamdera.sendToBackend (AuthToBackend msg))
    in
    ( authM, authCmd )


callbackForGoogleAuth : FrontendModel -> Url.Url -> Nav.Key -> ( FrontendModel, Cmd FrontendMsg )
callbackForGoogleAuth model url key =
    let
        ( authM, authCmd ) =
            Auth.Flow.init model
                "OAuthGoogle"
                url
                key
                (\msg -> Lamdera.sendToBackend (AuthToBackend msg))
    in
    ( authM, authCmd )


authCallbackCmd : FrontendModel -> Url.Url -> Nav.Key -> ( FrontendModel, Cmd FrontendMsg )
authCallbackCmd model url key =
    let
        { path } =
            url
    in
    case path of
        "/login/OAuthGoogle/callback" ->
            callbackForGoogleAuth model url key

        "/login/OAuthAuth0/callback" ->
            callbackForAuth0Auth model url key

        _ ->
            ( model, Cmd.none )


initWithAuth : Url.Url -> Nav.Key -> ( FrontendModel, Cmd FrontendMsg )
initWithAuth url key =
    let
        ( model, cmds ) =
            init url key

        -- Log model state after init but before authCallbackCmd
        -- _ = Debug.log "initWithAuth: Model after init" { route = model.currentRoute, login = model.login }

        ( finalModel, authCmd ) =
            authCallbackCmd model url key

        -- Log model state after authCallbackCmd
        -- _ = Debug.log "initWithAuth: Model after authCallbackCmd" { route = finalModel.currentRoute, login = finalModel.login }
    in
    -- Log just before returning
    Tuple.mapSecond
        (\finalCmd ->
            -- let _ = Debug.log "initWithAuth: Final Cmds being batched" () in -- Removed debug log
            Cmd.batch [ cmds, finalCmd, Lamdera.sendToBackend GetUserToBackend ]
        )
        ( finalModel, authCmd )


viewWithAuth : Model -> Browser.Document FrontendMsg
viewWithAuth model =
    let
        isDark =
            model.preferences.darkMode
        
        colors =
            Theme.getColors isDark
    in
    { title = "View Auth Test"
    , body =
        [ div
            [ Attr.style "margin" "20px"
            , Attr.style "font-family" "Arial, sans-serif"
            , Theme.primaryBg isDark
            , Theme.primaryText isDark
            ]
            [ h1
                [ Theme.primaryText isDark ]
                [ text "Auth0 Test" ]
            , case model.login of
                LoggedIn userInfo ->
                    div
                        [ Attr.style "padding" "20px"
                        , Attr.style "border" ("1px solid " ++ colors.border)
                        , Attr.style "border-radius" "5px"
                        , Attr.style "background-color" colors.secondaryBg
                        , Attr.style "max-width" "400px"
                        ]
                        [ div
                            [ Attr.style "margin-bottom" "15px"
                            , Attr.style "font-size" "16px"
                            , Attr.style "color" colors.primaryText
                            ]
                            [ text ("👤 Logged in as: " ++ userInfo.email) ]
                        , button
                            [ HE.onClick Logout
                            , Attr.style "background-color" colors.dangerBg
                            , Attr.style "color" colors.buttonText
                            , Attr.style "padding" "10px 15px"
                            , Attr.style "border" "none"
                            , Attr.style "border-radius" "4px"
                            , Attr.style "cursor" "pointer"
                            ]
                            [ text "Logout" ]
                        ]

                _ ->
                    div
                        [ Attr.style "padding" "20px"
                        , Attr.style "border" ("1px solid " ++ colors.border)
                        , Attr.style "border-radius" "5px"
                        , Attr.style "background-color" colors.secondaryBg
                        , Attr.style "max-width" "400px"
                        ]
                        [ p
                            [ Attr.style "margin-bottom" "15px"
                            , Attr.style "color" colors.primaryText 
                            ]
                            [ text "Please sign in to continue" ]
                        , button
                            [ HE.onClick Auth0SigninRequested
                            , Attr.style "background-color" colors.buttonBg
                            , Attr.style "color" colors.buttonText
                            , Attr.style "padding" "10px 15px"
                            , Attr.style "border" "none"
                            , Attr.style "border-radius" "4px"
                            , Attr.style "cursor" "pointer"
                            ]
                            [ text "Sign in with Auth0" ]
                        ]
            ]
        ]
    }


authUpdateFromBackend : Auth.Common.ToFrontend -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
authUpdateFromBackend authToFrontendMsg model =
    case authToFrontendMsg of
        Auth.Common.AuthInitiateSignin url ->
            if model.pendingAuth then
                let
                    ( newModel, cmd ) =
                        Auth.Flow.startProviderSignin url model
                in
                ( { newModel | pendingAuth = False, login = LoginTokenSent }, cmd )

            else
                ( model, Cmd.none )

        Auth.Common.AuthError err ->
            let
                ( newModel, cmd ) =
                    Auth.Flow.setError model err
            in
            ( { newModel | pendingAuth = False, login = NotLogged False }, cmd )

        Auth.Common.AuthSessionChallenge _ ->
            ( model, Cmd.none )
