module Pages.UserIouHistory exposing (view, viewTransactionList)

import Components.IouInputForm -- Import the shared component
import Dict exposing (Dict)
import Html exposing (Attribute, Html, button, div, fieldset, form, h2, input, label, li, option, p, select, span, table, tbody, td, text, th, thead, tr, ul) -- Adjusted imports
import Html.Attributes as Attr
import Html.Events exposing (keyCode, on, onInput, onSubmit) -- Removed unused events
import Json.Decode as Decode
import List.Extra
import Theme
import Time exposing (Month, Posix, Zone)
import Types exposing (FrontendModel, FrontendMsg(..), IouDirection(..), IouEntry, NewIouInput, Route(..), UserId)


view : FrontendModel -> Html FrontendMsg
view model =
    let
        currentUser = model.currentUser
        maybeUserId = case model.currentRoute of
                            Types.IouHistory maybeId -> maybeId
                            _ -> Nothing

        -- TODO: Handle Nothing cases more gracefully (e.g., show selector or error)
        effectiveCurrentUserEmail =
            case currentUser of
                Just user -> user.email
                Nothing -> "" -- Should not happen if page is protected

        effectiveOtherUserId =
            case maybeUserId of
                Just userId -> userId
                Nothing -> "" -- Need a way to select user or handle default view

        colors = Theme.getColors model.preferences.darkMode
    in
    div [ Attr.class "p-6", Theme.primaryBg model.preferences.darkMode, Theme.primaryText model.preferences.darkMode ]
        [ case maybeUserId of
            Just otherUserId ->
                div [ Attr.class "space-y-4" ]
                    [ h2 [ Attr.class "text-2xl font-semibold" ]
                        [ text ("IOU History with " ++ otherUserId) ]
                    -- Use the shared component here
                    , Components.IouInputForm.view model.newIouInput model.iouError colors
                    , viewTransactionList effectiveCurrentUserEmail otherUserId model.ious colors
                    ]
            Nothing ->
                div [ Attr.class "space-y-4" ]
                    [ h2 [ Attr.class "text-2xl font-semibold" ] [ text "Overall IOU Summary" ]
                    , p [ Theme.secondaryText model.preferences.darkMode ] [ text "Select a user to view history or implement summary view." ]
                    -- Use the shared component here too
                    , Components.IouInputForm.view model.newIouInput model.iouError colors
                    ]
        ]


-- Removed viewNewIouForm function as it's replaced by the shared component


viewTransactionList : UserId -> UserId -> Dict String IouEntry -> Theme.Colors -> Html FrontendMsg
viewTransactionList currentUserEmail otherUserId iouDict colors =
    let
        relevantIous : List IouEntry
        relevantIous =
            Dict.values iouDict
                |> List.filter
                    (\iou ->
                        (iou.creatorId == currentUserEmail && iou.otherPartyId == otherUserId)
                            || (iou.creatorId == otherUserId && iou.otherPartyId == currentUserEmail)
                    )
                |> List.sortBy (\iou -> Time.posixToMillis iou.createdAt)

        calculateBalanceChange : IouEntry -> Float
        calculateBalanceChange iou =
            let
                amount =
                    iou.amount

                -- Positive means other user owes current user
                -- Negative means current user owes other user
                balanceEffect =
                    case ( iou.creatorId == currentUserEmail, iou.direction ) of
                        ( True, Lent ) ->
                            amount -- I lent, they owe me

                        ( True, Borrowed ) ->
                            -amount -- I borrowed, I owe them

                        ( False, Lent ) ->
                            -amount -- They lent (to me), I owe them

                        ( False, Borrowed ) ->
                            amount -- They borrowed (from me), they owe me
            in
            balanceEffect

        getYear : IouEntry -> Int
        getYear iou =
            Time.toYear Time.utc iou.createdAt

        getMonth : IouEntry -> Time.Month
        getMonth iou =
            Time.toMonth Time.utc iou.createdAt

        iousByMonth : List ( ( Int, Time.Month ), List IouEntry )
        iousByMonth =
            relevantIous
                |> List.Extra.groupWhile (\a b -> getMonth a == getMonth b && getYear a == getYear b)
                |> List.map
                    (\( firstIouInGroup, monthGroup ) ->
                        Just
                            ( ( getYear firstIouInGroup, getMonth firstIouInGroup )
                            , firstIouInGroup :: monthGroup
                            )
                    )
                |> List.filterMap identity

        ( monthlyBalancesHtml, finalBalance ) =
            List.foldl
                (\( ( year, month ), iousInMonth ) ( accHtml, runningBalance ) ->
                    let
                        monthBalanceChange =
                            List.sum (List.map calculateBalanceChange iousInMonth)

                        endOfMonthBalance =
                            runningBalance + monthBalanceChange

                        monthHtml =
                            div [ Attr.class "mb-6 p-4 rounded shadow", Attr.style "background-color" colors.secondaryBg ]
                                [ h2 [ Attr.class "text-xl font-medium mb-3 text-center", Attr.style "color" colors.primaryText ]
                                    [ text (monthToString month ++ " " ++ String.fromInt year) ]
                                , table [ Attr.class "w-full table-auto border-collapse mx-auto", Attr.style "max-width" "800px" ]
                                    [ thead [ Attr.style "background-color" colors.primaryBg ]
                                        [ tr [ Attr.class "text-left", Attr.style "color" colors.primaryText ]
                                            [ th [ Attr.class "p-2 border", Attr.style "border-color" colors.border ] [ text "Day" ]
                                            , th [ Attr.class "p-2 border", Attr.style "border-color" colors.border ] [ text "Description" ]
                                            , th [ Attr.class "p-2 border text-right", Attr.style "border-color" colors.border ] [ text "Amount" ]
                                            , th [ Attr.class "p-2 border", Attr.style "border-color" colors.border ] [ text "Action" ]
                                            ]
                                        ]
                                    , tbody []
                                        (List.map (viewIouRow currentUserEmail colors) iousInMonth)
                                    ]
                                , p [ Attr.class "mt-4 font-semibold text-right", Attr.style "color" colors.primaryText, Attr.style "max-width" "800px", Attr.class "mx-auto" ]
                                    [ text ("End of Month Balance: " ++ formatCurrency endOfMonthBalance colors) ]
                                ]
                    in
                    ( monthHtml :: accHtml, endOfMonthBalance )
                )
                ( [], 0.0 )
                iousByMonth
    in
    if List.isEmpty monthlyBalancesHtml then
        p [ Attr.style "color" colors.secondaryText ] [ text "No transaction history with this user yet." ]

    else
        div [ Attr.class "space-y-6" ]
            (List.reverse monthlyBalancesHtml
                ++ [ p
                        [ Attr.class "mt-4 font-semibold text-right mx-auto"
                        , Attr.style "max-width" "800px"
                        , Attr.style "color" colors.primaryText
                        ]
                        [ text ("Current Overall Balance: " ++ formatCurrency finalBalance colors) ]
                   ]
            )


viewIouRow : UserId -> Theme.Colors -> IouEntry -> Html FrontendMsg
viewIouRow currentUserEmail colors iou =
    let
        isCurrentUserCreator = iou.creatorId == currentUserEmail

        ( actionText, balanceEffect ) =
            case ( isCurrentUserCreator, iou.direction ) of
                ( True, Lent ) -> ("You lent", iou.amount)
                ( True, Borrowed ) -> ("You borrowed", -iou.amount)
                ( False, Lent ) -> (iou.creatorId ++ " lent you", -iou.amount)
                ( False, Borrowed ) -> (iou.creatorId ++ " borrowed", iou.amount)

        amountColor =
            if balanceEffect > 0 then colors.accent else colors.dangerBg

        day =
             Time.toDay Time.utc iou.createdAt
                |> String.fromInt
                |> String.padLeft 2 '0'

    in
    tr [ Attr.style "color" colors.secondaryText ]
        [ td [ Attr.class "p-2 border font-mono text-center", Attr.style "border-color" colors.border ] [ text day ]
        , td [ Attr.class "p-2 border", Attr.style "border-color" colors.border ] [ text iou.description ]
        , td [ Attr.class "p-2 border text-right font-medium", Attr.style "border-color" colors.border, Attr.style "color" amountColor ]
            [ text (formatCurrency iou.amount colors) ]
        , td [ Attr.class "p-2 border", Attr.style "border-color" colors.border ] [ text actionText ]
        ]


formatCurrency : Float -> Theme.Colors -> String
formatCurrency amount colors =
    let
        prefix = if amount < 0 then "-" else ""
        absAmount = abs amount
        formatted = String.fromFloat absAmount
    in
    prefix ++ "$" ++ formatted


monthToString : Time.Month -> String
monthToString month =
    case month of
        Time.Jan -> "January"
        Time.Feb -> "February"
        Time.Mar -> "March"
        Time.Apr -> "April"
        Time.May -> "May"
        Time.Jun -> "June"
        Time.Jul -> "July"
        Time.Aug -> "August"
        Time.Sep -> "September"
        Time.Oct -> "October"
        Time.Nov -> "November"
        Time.Dec -> "December" 