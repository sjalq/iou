module Pages.PageFrame exposing (viewFooter, viewHeader)

import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (onClick)
import Route exposing (..)
import Theme -- Import the new Theme module
import Types exposing (..)

-- Remove darkModeStyles function

-- Hardcode the other user email for the example page
otherUserEmailForExample : UserId
otherUserEmailForExample = "them@example.com"

viewTabs : FrontendModel -> Html FrontendMsg
viewTabs model =
    let
        isDark =
            model.preferences.darkMode
        
        colors =
            Theme.getColors isDark
    in
    div [ Attr.class "flex justify-between mb-5 px-4 items-center" ]
        [ div [ Attr.class "flex" ]
            -- TEMPORARY: Always show only the Default tab
            [ viewTab "Default" Default model.currentRoute model.preferences ]
            -- (viewTab "Default" Default model.currentRoute model.preferences
            --     :: (case model.currentUser of
            --             Just user ->
            --                 if user.isSysAdmin then
            --                     [ viewTab "Admin" (Admin AdminDefault) model.currentRoute model.preferences ]

            --                 else
            --                     []

            --             Nothing ->
            --                 []
            --        )
            -- )
        , div [ Attr.class "flex items-center" ]
            [ button
                [ onClick ToggleDarkMode
                , Attr.class "mr-4 px-2 py-1 rounded border"
                , Theme.primaryBorder isDark
                , Theme.primaryText isDark
                ]
                [ text (if isDark then "☀️" else "🌙")
                ]
            -- TEMPORARY: Always show Login button
            , case model.login of
                LoggedIn userInfo ->
                    div [ Attr.class "flex items-center" ]
                        [ span [ Attr.class "mr-2", Attr.style "color" colors.secondaryText ]
                            [ text userInfo.email ]
                        , button
                            [ onClick Logout
                            , Attr.class "px-4 py-1 rounded"
                            , Attr.style "background-color" colors.dangerBg
                            , Attr.style "color" colors.buttonText
                            ]
                            [ text "Logout" ]
                        ]

                LoginTokenSent ->
                    div [ Attr.class "flex items-center" ]
                        [ span [ Attr.class "mr-2 animate-pulse", Attr.style "color" colors.secondaryText ]
                            [ text "Authenticating..." ]
                        ]

                NotLogged pendingAuth ->
                    if pendingAuth then
                        button
                            [ Attr.disabled True
                            , Attr.class "px-4 py-1 rounded cursor-wait"
                             , Attr.style "background-color" colors.buttonBg
                             , Attr.style "color" colors.buttonText
                            , Attr.style "opacity" "0.7"
                            ]
                            [ text "Authenticating..." ]
                    else
                        button
                            [ onClick Auth0SigninRequested
                            , Attr.class "px-4 py-1 rounded"
                            , Attr.style "background-color" colors.buttonBg
                            , Attr.style "color" colors.buttonText
                            ]
                            [ text "Login" ]

                JustArrived ->
                    button
                        [ onClick Auth0SigninRequested
                        , Attr.class "px-4 py-1 rounded"
                        , Attr.style "background-color" colors.buttonBg
                        , Attr.style "color" colors.buttonText
                        ]
                        [ text "Login" ]
            ]
        ]


viewTab : String -> Route -> Route -> Preferences -> Html FrontendMsg
viewTab label page currentPage preferences =
    let
        isDark =
            preferences.darkMode
        
        isActive =
            page == currentPage
        
        colors =
            Theme.getColors isDark
        
        bgColor =
            if isActive then
                colors.secondaryBg
            else
                colors.primaryBg

        textColor =
            colors.primaryText
    in
    a
        [ Attr.href (Route.toString page)
        , Attr.class "px-4 py-2 mx-2 border cursor-pointer rounded"
        , Attr.style "background-color" bgColor
        , Attr.style "color" textColor
        , Attr.style "border-color" colors.border
        ]
        [ text label ]


-- New Header View
viewHeader : FrontendModel -> Html FrontendMsg
viewHeader model =
    let
        isDark = model.preferences.darkMode
        colors = Theme.getColors isDark
    in
    header
        [ Attr.class "p-4 shadow-md"
        , Attr.style "background-color" colors.primaryBg
        ]
        [ viewTabs model -- Reusing existing tabs view
        ]


-- New Footer View
viewFooter : FrontendModel -> Html FrontendMsg
viewFooter model =
    let
        isDark = model.preferences.darkMode
        colors = Theme.getColors isDark
    in
    footer
        [ Attr.class "p-4 text-center text-sm mt-auto"
        , Attr.style "background-color" colors.secondaryBg
        , Attr.style "color" colors.secondaryText
        ]
        [ text "© 2024 IOU App" ]
