module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }



{-
   MODEL
   * Model type
   * Initialize model with empty values
-}


type alias Model =
    { quote : String
    }


init : ( Model, Cmd Msg )
init =
    ( Model "", fetchRandomQuoteCmd )



{-
   UPDATE
   * API routes
   * GET
   * Messages
   * Update case
-}


api : String
api =
    "http://localhost:3031/"


randomQuoteUrl : String
randomQuoteUrl =
    api ++ "api/random-quote"



-- Get a random quote


fetchRandomQuote : Http.Request String
fetchRandomQuote =
    Http.getString randomQuoteUrl


fetchRandomQuoteCmd : Cmd Msg
fetchRandomQuoteCmd =
    Http.send FetchRandomQuoteCompleted fetchRandomQuote


fetchRandomQuoteCompleted : Model -> Result Http.Error String -> ( Model, Cmd Msg )
fetchRandomQuoteCompleted model result =
    case result of
        Ok newQuote ->
            ( { model | quote = newQuote }, Cmd.none )

        Err _ ->
            ( model, Cmd.none )


type Msg
    = GetQuote
    | FetchRandomQuoteCompleted (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetQuote ->
            ( model, fetchRandomQuoteCmd )

        FetchRandomQuoteCompleted result ->
            fetchRandomQuoteCompleted model result



{-
   View
-}


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ h2 [ class "text-center" ] [ text "Random Quotes by Random People" ]
        , p [ class "text-center" ]
            [ button [ class "btn btn-success", onClick GetQuote ] [ text "Grab a quote!" ]
            ]
        , blockquote []
            [ p [] [ text model.quote ]
            ]
        ]
