module Component.Application.Init exposing(init, setRoute)

-- Core Imports
import Http
import Task

-- Library Imports
import Bootstrap.Carousel as Carousel exposing (defaultStateOptions)
import Bootstrap.Navbar as Navbar
import Navigation
import Json.Decode as Decode exposing (Value)
import Phoenix.Socket
import Window

-- Local Imports
import Component.Application.Model exposing(Model)
import Component.Page.Component
import Data.User as User
import Msg
import Route
import Util exposing ((=>))

socketServer : String
socketServer =
    "ws://localhost:4000/socket/websocket"


fetchAuthUser : Http.Request User.User
fetchAuthUser =
  Http.get "/auth/user" User.decoder

getAuthUser : Cmd Msg.Msg
getAuthUser =
  Http.send Msg.AuthUser fetchAuthUser

getWindowSize : Cmd Msg.Msg
getWindowSize =
    Task.perform (\s -> Msg.WindowResize s) Window.size

setRoute : Maybe Route.Route -> Model -> ( Model, Cmd Msg.Msg )
setRoute maybeRoute model =
    let
        session =
            model.session

        toPage toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd ) =
                    subUpdate subMsg subModel
            in
            ( { model | page = Component.Page.Component.Loaded (toModel newModel) }, Cmd.map toMsg newCmd )

        -- errored = pageErrored model
    in
   case maybeRoute of
        Nothing ->
            { model | page = Component.Page.Component.Loaded Component.Page.Component.NotFound } => Cmd.none

        Just Route.Home ->
            { model | page = Component.Page.Component.Loaded Component.Page.Component.Home } => Cmd.none

        Just Route.Map ->
            { model | page = Component.Page.Component.Loaded Component.Page.Component.Map } => Cmd.none

        Just Route.SignIn ->
            { model | page = Component.Page.Component.Loaded Component.Page.Component.SignIn } => Cmd.none

        Just Route.SignUp ->
            { model | page = Component.Page.Component.Loaded Component.Page.Component.SignUp } => Cmd.none

init : Value -> Navigation.Location -> ( Model, Cmd Msg.Msg )
init value location =
    let
        ( navbarState, navbarCmd ) =
            Navbar.initialState Msg.NavbarMsg
        ( routeState, routeCmd ) =
            setRoute (Route.fromLocation location)
                { history = [ location ]
                , navbar =
                    { state = navbarState
                    }
                , carousel = Carousel.initialStateWithOptions
                    { defaultStateOptions
                    | interval = Just 5000 -- Change slide every 5 seconds
                    , pauseOnHover = False -- Prevent the default behavior to pause the transitions on mouse hover
                    }
                , page = Component.Page.Component.Loaded Component.Page.Component.initialPage
                , session =
                    {
                    user = Nothing
                    , socket = Phoenix.Socket.init socketServer
                        |> Phoenix.Socket.withDebug
                    }
                , map =
                    { latitude = 48.2082
                    , longitude = 16.3738
                    , zoom = 5
                    }
                , window =
                    {
                        size = Nothing
                    }
                }

    in

        ( routeState
        , Cmd.batch [ navbarCmd, routeCmd, getWindowSize, getAuthUser ] -- (Task.perform identity << Task.succeed) Msg.FetchUser
        )