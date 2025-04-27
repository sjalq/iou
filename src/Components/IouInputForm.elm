module Components.IouInputForm exposing (view)

import Html exposing (..)
import Html.Attributes as Attr exposing (style, class, value, placeholder, type_, step, name, checked)
import Html.Events exposing (onInput, onClick, onSubmit)
import Theme
import Types exposing (..)

-- Mock users for the dropdown - Keep it here for now, or pass it in if needed elsewhere
mockUsers : List ( String, String )
mockUsers =
    [ ( "alice@example.com", "Alice" )
    , ( "bob@example.com", "Bob" )
    , ( "charlie@example.com", "Charlie" )
    , ( "them@example.com", "Them Example" )
    , ( "s.dormehl@sakeliga.org.za", "Sakeliga SD" )
    ]


view : NewIouInput -> Maybe String -> Theme.Colors -> Html FrontendMsg
view iouInput maybeError colors =
    div [ class "p-4 rounded shadow", style "background-color" colors.secondaryBg ] 
        [ h2 [ class "text-xl font-semibold mb-3", style "color" colors.primaryText ]
            [ text "Add New IOU" ]
        , form [ onSubmit SubmitNewIou, class "flex items-center space-x-3 border rounded p-3 mx-auto", style "border-color" colors.border, style "max-width" "800px" ] 
            [ -- "Who" Dropdown
              select [ class "p-2 border rounded", style "border-color" colors.border, style "background-color" colors.secondaryBg, style "color" colors.primaryText, onInput UpdateNewIouOtherParty, value iouInput.otherPartyId ]
                ( [ option [ value "" ] [ text "Select User" ] ]
                   ++ List.map (\( userValue, userLabel ) -> option [ value userValue ] [ text userLabel ]) mockUsers
                )

            -- "Amount" Input (Number)
            , input
                [ class "p-2 border rounded w-24"
                , style "border-color" colors.border
                , style "background-color" colors.secondaryBg
                , style "color" colors.primaryText
                , placeholder "Amount"
                , type_ "number"
                , step "any"
                , onInput UpdateNewIouAmount
                , value iouInput.amount
                ] 
                []

            -- "Description" Input
            , input
                [ class "p-2 border rounded flex-grow"
                , style "border-color" colors.border
                , style "background-color" colors.secondaryBg
                , style "color" colors.primaryText
                , placeholder "Description"
                , onInput UpdateNewIouDescription
                , value iouInput.description
                ]
                []

            -- "Direction" Radio Buttons
            , div [ class "flex items-center space-x-2" ]
                [ label [ class "flex items-center space-x-1", style "color" colors.secondaryText ]
                    [ input [ type_ "radio", name "direction", value "Lent", checked (iouInput.direction == Lent), onClick (UpdateNewIouDirection Lent) ] []
                    , span [] [ text "They Owe" ] 
                    ]
                , label [ class "flex items-center space-x-1", style "color" colors.secondaryText ]
                    [ input [ type_ "radio", name "direction", value "Borrowed", checked (iouInput.direction == Borrowed), onClick (UpdateNewIouDirection Borrowed) ] []
                    , span [] [ text "I Owe" ] 
                    ]
                ]

            -- Submit Button
            , button
                [ class "px-4 py-2 rounded", style "background-color" colors.buttonBg, style "color" colors.buttonText, type_ "submit" ]
                [ text "Add IOU" ]
            ]
        , case maybeError of
            Just errMsg ->
                p [ class "text-red-500 text-sm mt-2" ] [ text errMsg ]

            Nothing ->
                text ""
        ] 