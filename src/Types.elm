module Types exposing (..)

import Auth.Common
import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Http
import Lamdera
import Time exposing (Posix)
import Url exposing (Url)
-- import Fusion.Patch
-- import Fusion
import Html exposing (Attribute)



{- Represents a currently connection to a Lamdera client -}


type alias ConnectionId =
    Lamdera.ClientId



{- Represents the browser cookie Lamdera uses to identify a browser -}


type alias BrowserCookie =
    Lamdera.SessionId


type Route
    = Default
    | Admin AdminRoute
    | NotFound
    | IouHistory (Maybe UserId)


type AdminRoute
    = AdminDefault
    | AdminLogs
    | AdminFetchModel
    -- | AdminFusion


type alias AdminPageModel =
    { logs : List String
    , isAuthenticated : Bool
    , remoteUrl : String
    }


type alias FrontendModel =
    { key : Key
    , currentRoute : Route
    , adminPage : AdminPageModel
    , authFlow : Auth.Common.Flow
    , authRedirectBaseUrl : Url
    , login : LoginState
    , currentUser : Maybe UserFrontend
    , pendingAuth : Bool
    -- , fusionState : Fusion.Value
    , preferences : Preferences
    , ious : Dict IouId IouEntry
    , iouError : Maybe String
    , isLoadingIous : Bool
    , newIouInput : NewIouInput
    }


type alias BackendModel =
    { logs : List String
    , pendingAuths : Dict Lamdera.SessionId Auth.Common.PendingAuth
    , sessions : Dict Lamdera.SessionId Auth.Common.UserInfo
    , users : Dict Email User
    , pollingJobs : Dict PollingToken (PollingStatus PollData)
    , ious : Dict IouId IouEntry
    }

    
type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | UrlRequested UrlRequest
    | NoOpFrontendMsg
    | DirectToBackend ToBackend
    --- Admin
    | Admin_RemoteUrlChanged String
    | GoogleSigninRequested
    | Auth0SigninRequested
    | Logout
    | ToggleDarkMode
    --- Fusion
    -- | Admin_FusionPatch Fusion.Patch.Patch
    -- | Admin_FusionQuery Fusion.Query
    --- IOU Msgs
    | GotIouUpdate (Dict IouId IouEntry)
    | IouOpFailed String
    | DeleteIouRequest IouId
    | CreateIouRequest IouEntryData
    | UpdateNewIouDescription String
    | UpdateNewIouAmount String
    | UpdateNewIouDirection IouDirection
    | UpdateNewIouOtherParty String
    | SubmitNewIou


type ToBackend
    = NoOpToBackend
    | Admin_FetchLogs
    | Admin_ClearLogs
    | Admin_FetchRemoteModel String
    | AuthToBackend Auth.Common.ToBackend
    | GetUserToBackend
    | LoggedOut
    | SetDarkModePreference Bool
    --- Fusion
    -- | Fusion_PersistPatch Fusion.Patch.Patch
    -- | Fusion_Query Fusion.Query
    --- IOU Msgs
    | FetchIous
    | CreateIou IouEntryData
    | DeleteIou IouId
    | UpdateNewIou IouEntryData


type BackendMsg
    = NoOpBackendMsg
    | Log String
    | GotRemoteModel (Result Http.Error BackendModel)
    | AuthBackendMsg Auth.Common.BackendMsg
    | GotJobTime PollingToken Int
      -- example to show polling mechanism
    | GotCryptoPriceResult PollingToken (Result Http.Error String)
    | StoreTaskResult PollingToken (Result String String)


type ToFrontend
    = NoOpToFrontend
      -- Admin page
    | Admin_Logs_ToFrontend (List String)
    | AuthToFrontend Auth.Common.ToFrontend
    | AuthSuccess Auth.Common.UserInfo
    | UserInfoMsg (Maybe Auth.Common.UserInfo)
    | UserDataToFrontend UserFrontend
    | PermissionDenied ToBackend
    -- | Admin_FusionResponse Fusion.Value
    --- IOU Msgs
    | IouSync (Dict IouId IouEntry)
    | IouDeletedSuccessfully IouId
    | IouOpError String


type alias Email =
    String


type alias User =
    { email : Email
    , preferences : Preferences
    }


type alias UserFrontend =
    { email : Email
    , isSysAdmin : Bool
    , role : String
    , preferences : Preferences
    }


type LoginState
    = JustArrived
    | NotLogged Bool
    | LoginTokenSent
    | LoggedIn Auth.Common.UserInfo



-- Role types


type Role
    = SysAdmin
    | UserRole
    | Anonymous



-- Polling types


type alias PollingToken =
    String


type PollingStatus a
    = Busy
    | BusyWithTime Int
    | Ready (Result String a)


type alias PollData =
    String


-- USER RELATED TYPES
type alias Preferences =
    { darkMode : Bool
    }


-- IOU RELATED TYPES
type alias IouId =
    String


type IouDirection
    = Lent -- I lent money to someone
    | Borrowed -- I borrowed money from someone


type alias IouEntry =
    { id : IouId
    , creatorId : UserId -- Assumes UserId is Email for now
    , otherPartyId : UserId -- Assumes UserId is Email for now
    , amount : Float
    , description : String
    , createdAt : Posix
    , direction : IouDirection
    }


type alias IouEntryData =
    { otherPartyId : UserId -- Assumes UserId is Email for now
    , amount : Float
    , description : String
    , direction : IouDirection
    }


-- USER RELATED TYPES
type alias UserId =
    Email -- Define UserId alias


-- Helper for the form
type alias NewIouInput =
    { otherPartyId : String
    , amount : String -- Store as string for input validation
    , description : String
    , direction : IouDirection -- Default to Lent
    }
