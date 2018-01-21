module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)


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
    { username : String
    , password : String
    , token : String
    , errorMsg : String
    , quote : String
    }


init : ( Model, Cmd Msg )
init =
    ( Model "" "" "" "" "", fetchRandomQuoteCmd )



{-
   UPDATE
   * API routes
   * GET and POST
   * Encode request body
   * Decode responses
   * Messages
   * Update case
-}
-- API request URLs


api : String
api =
    "http://localhost:3031/"


randomQuoteUrl : String
randomQuoteUrl =
    api ++ "api/random-quote"


registerUrl : String
registerUrl =
    api ++ "users"



-- Encode user to construct POST request body (for register and log in)


userEncoder : Model -> Encode.Value
userEncoder model =
    Encode.object
        [ ( "username", Encode.string model.username )
        , ( "password", Encode.string model.password )
        ]



-- Decode POST response to get access token


tokenDecoder : Decoder String
tokenDecoder =
    Decode.field "access_token" Decode.string



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



-- POST register/login request
-- authUser takes model as an argument and a string as an argument and returns a request that succeeds with a string


authUser : Model -> String -> Http.Request String
authUser model apiUrl =
    let
        body =
            model
                |> userEncoder
                |> Http.jsonBody
    in
    Http.post apiUrl body tokenDecoder


authUserCmd : Model -> String -> Cmd Msg
authUserCmd model apiUrl =
    Http.send GetTokenCompleted (authUser model apiUrl)


getTokenCompleted : Model -> Result Http.Error String -> ( Model, Cmd Msg )
getTokenCompleted model result =
    case result of
        Ok newToken ->
            ( { model | token = newToken, password = "", errorMsg = "" } |> Debug.log "Got new token", Cmd.none )

        Err error ->
            ( { model | errorMsg = toString error }, Cmd.none )


type Msg
    = GetQuote
    | FetchRandomQuoteCompleted (Result Http.Error String)
    | SetUsername String
    | SetPassword String
    | ClickRegisterUser
    | GetTokenCompleted (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetQuote ->
            ( model, fetchRandomQuoteCmd )

        FetchRandomQuoteCompleted result ->
            fetchRandomQuoteCompleted model result

        SetUsername username ->
            ( { model | username = username }, Cmd.none )

        SetPassword password ->
            ( { model | password = password }, Cmd.none )

        ClickRegisterUser ->
            ( model, authUserCmd model registerUrl )

        GetTokenCompleted result ->
            getTokenCompleted model result



{-
   View
   * Hide sections of view depending on authentication state of the model
   * Get a quote
   * Register
-}


view : Model -> Html Msg
view model =
    let
        -- Is the user logged in?
        loggedIn : Bool
        loggedIn =
            if String.length model.token > 0 then
                True
            else
                False

        -- If the user is logged in, show greeting, else show login/register form
        authBoxView =
            let
                -- If there's an error on auth, show the error alert
                showError : String
                showError =
                    if String.isEmpty model.errorMsg then
                        "hidden"
                    else
                        ""

                -- Greet logged in user by username
                greeting : String
                greeting =
                    "Hello, " ++ model.username ++ "!"
            in
            if loggedIn then
                div [ id "greeting" ]
                    [ h3 [ class "text-center" ] [ text greeting ]
                    , p [ class "text-center" ] [ text "You have access!" ]
                    ]
            else
                div [ id "form" ]
                    [ h2 [ class "text-center" ] [ text "Log in or Register" ]
                    , p [ class "text-center" ] [ text "If you already have an account, please Log In. Otherwise, enter your desired username and password and Register." ]
                    , div [ class showError ]
                        [ div [ class "alert alert-danger" ] [ text model.errorMsg ]
                        ]
                    , div [ class "form-group row" ]
                        [ div [ class "col-md-offset-2 col-md-8" ]
                            [ label [ for "username" ] [ text "Username:" ]
                            , input [ id "username", type_ "text", class "form-control", Html.Attributes.value model.username, onInput SetUsername ] []
                            ]
                        ]
                    , div [ class "form-group row" ]
                        [ div [ class "col-md-offset-2 col-md-8" ]
                            [ label [ for "password" ] [ text "Password:" ]
                            , input [ id "password", type_ "password", class "form-control", Html.Attributes.value model.password, onInput SetPassword ] []
                            ]
                        ]
                    , div [ class "text-center" ]
                        [ button [ class "btn btn-link", onClick ClickRegisterUser ] [ text "Register" ]
                        ]
                    ]
    in
    div [ class "container" ]
        [ h2 [ class "text-center" ] [ text "Chuck Norris Quotes" ]
        , p [ class "text-center" ]
            [ button [ class "btn btn-success", onClick GetQuote ] [ text "Grab a quote!" ]
            ]

        -- Blockquote with quote
        , blockquote []
            [ p [] [ text model.quote ]
            ]
        , div [ class "jumbotron text-left" ]
            [ -- Login/Register form or user greeting
              authBoxView
            ]
        ]
