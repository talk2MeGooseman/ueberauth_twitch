# Überauth Twitch

[![Hex Version](https://img.shields.io/hexpm/v/ueberauth_twitch_strategy.svg)](https://hex.pm/packages/ueberauth_twitch_strategy)
[![Build Status](https://travis-ci.org/mtchavez/ueberauth_twitch.svg?branch=master)](https://travis-ci.org/mtchavez/ueberauth_twitch)
[![Coverage Status](https://coveralls.io/repos/github/mtchavez/ueberauth_twitch/badge.svg?branch=master)](https://coveralls.io/github/mtchavez/ueberauth_twitch?branch=master)

> Twitch OAuth2 strategy for Überauth.

## Installation

1. Setup your application in Twitch under your profile [applications menu][twitch-apps]

1. Add `:ueberauth_twitch_strategy` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_twitch_strategy, "~> 0.2"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_twitch_strategy]]
    end
    ```

1. Add Twitch to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        identity: { Ueberauth.Strategy.Identity, [
            callback_methods: ["POST"],
            uid_field: :email,
            nickname_field: :username,
          ] },
        twitch: {Ueberauth.Strategy.Twitch, [default_scope: "read_user"]},
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Twitch.OAuth,
      client_id: System.get_env("TWITCH_CLIENT_ID"),
      client_secret: System.get_env("TWITCH_CLIENT_SECRET"),
      redirect_uri: System.get_env("TWITCH_REDIRECT_URI")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller

      pipeline :browser do
        plug Ueberauth
        ...
       end
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. You controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example][example-app] application
on how to integrate other strategies. Adding Twitch should be similar to Github.

## Calling

Depending on the configured url you can initial the request through:

    /oauth2/authorize

Or with options:

    /oauth2/authorize?scope=api read_user


```elixir
config :ueberauth, Ueberauth,
  providers: [
    identity: { Ueberauth.Strategy.Identity, [
        callback_methods: ["POST"],
        uid_field: :email,
        nickname_field: :username,
      ] },
    twitch: {Ueberauth.Strategy.Twitch, [default_scope: "read_user"]},
  ]
```

It is also possible to disable the sending of the `redirect_uri` to Twitch. This
is particularly useful when your production application sits behind a proxy that
handles SSL connections. In this case, the `redirect_uri` sent by `Ueberauth`
will start with `http` instead of `https`, and if you configured your Twitch OAuth
application's callback URL to use HTTPS, Twitch will throw an `uri_missmatch` error.
In addition if the `redirect_uri` on the the authorize request **must match**
the `redirect_uri` on the token request.


## Documentation

The docs can be found at [ueberauth_twitch][package-docs] on [Hex Docs][hex-docs].

[hex-docs]: https://hexdocs.pm
[package-docs]: https://hexdocs.pm/ueberauth_twitch_strategy
