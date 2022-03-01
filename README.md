# Überauth Twitch

[![Hex Version](https://img.shields.io/hexpm/v/ueberauth_twitch.svg)](https://hex.pm/packages/ueberauth_twitch)

> Twitch OAuth2 strategy for Überauth.

## Installation

1. Setup your application in Twitch under your profile [applications menu][twitch-apps]

1. Add `:ueberauth_twitch` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_twitch, "~> 0.1.0"}]
    end
    ```

1. Add Twitch to your Überauth configuration to your `config.exs`:

    ```elixir
    config :ueberauth, Ueberauth,
        twitch: {Ueberauth.Strategy.Twitch, [default_scope: "user:read:email"]}
      ]
    ```

1.  Add your provider configuration to your `config.exs` next, all this information should mirror what you have for your
    Twitch app:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Twitch.OAuth,
      client_id: System.get_env("TWITCH_CLIENT_ID"),
      client_secret: System.get_env("TWITCH_CLIENT_SECRET"),
      redirect_uri: System.get_env("TWITCH_REDIRECT_URI")
    ```

1.  Include the Überauth plug in your `router.exs` in the browser or custom pipeline:

    ```elixir
    defmodule TwitchWeb.Router do
       use TwitchWeb, :router

       pipeline :browser do
         plug Ueberauth
       ...
      end
    end
    ```

1.  Define the request and callback routes in your `router.exs`:

    ```elixir
    scope "/auth", TwitchWeb do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. Create a new controller or use an existing controller that implements callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses from Twitch.

    ```elixir
      defmodule TwitchWeb.AuthController do
        use TwitchWeb, :controller

        def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
          Logger.debug(_fails)
          conn
          |> put_flash(:error, "Failed to authenticate.")
          |> redirect(to: "/")
        end

        def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
          # This is an example of how you can pass the auth information to 
          # a function that you implement that will register or login a user
          case UserFromAuth.find_or_create(auth) do
            {:ok, user} ->
              conn
              |> put_flash(:info, "Successfully authenticated.")
              |> put_session(:current_user, user)
              |> configure_session(renew: true)
              |> redirect(to: "/")

            {:error, reason} ->
              conn
              |> put_flash(:error, reason)
              |> redirect(to: "/")
          end
        end
      end
    ```

## Calling

Once your setup, you can initiate auth using the following URL, unless you changed the routes from the guide:

    /auth/twitch

<!-- ## Documentation

The docs can be found at [ueberauth_twitch][package-docs] on [Hex Docs][hex-docs].

[hex-docs]: https://hexdocs.pm
[package-docs]: https://hexdocs.pm/ueberauth_twitch -->
