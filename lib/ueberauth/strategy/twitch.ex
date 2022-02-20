defmodule Ueberauth.Strategy.Twitch do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with Twitch.

  ### Setup

  Create an application in Twitch for you to use.

  Register a new application at: [your twitch developer page](https://dev.twitch.tv/) and get the `client_id` and `client_secret`.

  Include the provider in your configuration for Ueberauth

      config :ueberauth, Ueberauth,
        providers: [
          twitch: { Ueberauth.Strategy.Twitch, [] }
        ]

  Then include the configuration for twitch.

      config :ueberauth, Ueberauth.Strategy.Twitch.OAuth,
        client_id: System.get_env("TWITCH_CLIENT_ID"),
        client_secret: System.get_env("TWITCH_CLIENT_SECRET")

  If you haven't already, create a pipeline and setup routes for your callback handler

      pipeline :auth do
        Ueberauth.plug "/auth"
      end

      scope "/auth" do
        pipe_through [:browser, :auth]

        get "/:provider/callback", AuthController, :callback
      end


  Create an endpoint for the callback where you will handle the `Ueberauth.Auth` struct

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller

        def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
          # do things with the failure
        end

        def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
          # do things with the auth
        end
      end

  You can edit the behaviour of the Strategy by including some options when you register your provider.

  Default is `:id`

  To set the default 'scopes' (permissions):

      config :ueberauth, Ueberauth,
        providers: [
          twitch: { Ueberauth.Strategy.Twitch, [default_scope: ""] }
        ]

  Default is "api read_user read_registry"
  """
  use Ueberauth.Strategy,
    default_scope: "",
    oauth2_module: Ueberauth.Strategy.Twitch.OAuth

  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra
  alias Ueberauth.Auth.Info

  @doc """
  Handles the initial redirect to the twitch authentication page.

  To customize the scope (permissions) that are requested by twitch include them as part of your url:

      "/oauth2/token?scope=api read_user read_registry"

  You can also include a `state` param that twitch will return to you.
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)

    params =
      [scope: scopes]
      |> with_optional(:redirect_uri, conn)
      |> with_state_param(conn)

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [params]))
  end

  @doc """
  Handles the callback from Twitch. When there is a failure from Twitch the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from Twitch is returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    module = option(conn, :oauth2_module)
    token = apply(module, :get_token!, [[code: code]])

    if token.access_token == nil do
      set_errors!(conn, [
        error(token.other_params["error"], token.other_params["error_description"])
      ])
    else
      fetch_user(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw Twitch response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:twitch_user, nil)
    |> put_private(:twitch_token, nil)
  end

  @doc """
  Fetches the uid field from the Twitch response. This defaults to the option `uid_field` which in-turn defaults to `id`
  """
  def uid(conn) do
    %{"data" => [user]} = conn.private.twitch_user
    user["id"]
  end

  @doc """
  Includes the credentials from the Twitch response.
  """
  def credentials(conn) do
    token = conn.private.twitch_token
    scopes = token.other_params["scope"] || []

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      expires: !!token.expires_at,
      scopes: scopes
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    twitch_user_data = conn.private.twitch_user
    %{"data" => [user]} = twitch_user_data

    %Info{
      name: user["display_name"],
      nickname: user["login"],
      email: user["email"],
      description: user["description"],
      image: user["profile_image_url"]
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Twitch callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.twitch_token,
        user: conn.private.twitch_user
      }
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :twitch_token, token)

    case Ueberauth.Strategy.Twitch.OAuth.get(token, "https://api.twitch.tv/helix/users") do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %OAuth2.Response{status_code: status_code, body: user}}
      when status_code in 200..399 ->
        put_private(conn, :twitch_user, user)

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])

      {:error, %OAuth2.Response{body: %{"message" => reason}}} ->
        set_errors!(conn, [error("OAuth2", reason)])

      {:error, _} ->
        set_errors!(conn, [error("OAuth2", "uknown error")])
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn) || [], key, Keyword.get(default_options(), key))
  end

  defp with_optional(opts, key, conn) do
    if option(conn, key), do: Keyword.put(opts, key, option(conn, key)), else: opts
  end
end
