module Pages.Default exposing (..)

import Components.IouInputForm
import Html exposing (..)
import Html.Attributes as Attr exposing (style, class)
import Theme
import Types exposing (..)


init : FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
init model =
    ( model, Cmd.none )


view : FrontendModel -> Theme.Colors -> Html FrontendMsg
view model colors =
    div [ style "background-color" colors.primaryBg, class "min-h-screen" ]
        [ div [ class "container mx-auto px-4 py-8" ]
            [ h1 [ class "text-3xl font-bold mb-4", style "color" colors.primaryText ]
                [ text "IOU Dashboard" ]

            , Components.IouInputForm.view model.newIouInput model.iouError colors

            , div [ class "mt-8" ]
                [ h2 [ class "text-2xl font-semibold mb-4", style "color" colors.primaryText ] [ text "Existing IOUs (Summary)" ]
                , p [ style "color" colors.secondaryText ] [ text "(IOU display area - TBD)" ]
                ]
            ]
        ]
