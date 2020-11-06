defmodule UeberauthTwitchTest do
  use ExUnit.Case, async: false
  use Plug.Test

  import Plug.Conn

  doctest UeberauthTwitch

  def set_options(routes, conn, opt) do
    case Enum.find_index(routes, &(elem(&1, 0) == {conn.request_path, conn.method})) do
      nil ->
        routes

      idx ->
        update_in(routes, [Access.at(idx), Access.elem(1), Access.elem(2)], &%{&1 | options: opt})
    end
  end

  test "handle_request!" do
    conn =
      conn(:get, "/auth/twitch", %{
        client_id: "12345",
        client_secret: "98765",
        redirect_uri: "http://localhost:4000/auth/twitch/callback"
      })

    routes =
      Ueberauth.init()
      |> set_options(conn, default_scope: "read_user")

    resp = Ueberauth.call(conn, routes)

    assert resp.status == 302
    assert [location] = get_resp_header(resp, "location")

    redirect_uri = URI.parse(location)
    assert redirect_uri.host == "id.twitch.tv"
    assert redirect_uri.path == "/oauth2/authorize"

    assert %{
             "client_id" => "test_client_id",
             "redirect_uri" => "http://www.example.com/auth/twitch/callback",
             "response_type" => "code",
             "scope" => "read_user"
           } = Plug.Conn.Query.decode(redirect_uri.query)
  end

  describe "handle_callback!" do
    test "with no code" do
      conn = %Plug.Conn{}
      result = Ueberauth.Strategy.Twitch.handle_callback!(conn)
      failure = result.assigns.ueberauth_failure
      assert length(failure.errors) == 1
      [no_code_error] = failure.errors

      assert no_code_error.message_key == "missing_code"
      assert no_code_error.message == "No code received"
    end
  end

  describe "handle_cleanup!" do
    test "clears twitch_user from conn" do
      conn =
        %Plug.Conn{}
        |> Plug.Conn.put_private(:twitch_user, %{username: "talk2megooseman"})
        |> Plug.Conn.put_private(:twitch_token, "test-token")

      result = Ueberauth.Strategy.Twitch.handle_cleanup!(conn)
      assert result.private.twitch_user == nil
      assert result.private.twitch_token == nil
    end
  end

  describe "uid" do
    test "uid_field not found" do
      conn =
        %Plug.Conn{}
        |> Plug.Conn.put_private(:twitch_user, %{uid: "not-found-uid"})

      assert Ueberauth.Strategy.Twitch.uid(conn) == nil
    end

    test "uid_field returned" do
      uid = "abcd1234abcd1234"

      conn =
        %Plug.Conn{}
        |> Plug.Conn.put_private(:twitch_user, %{"id" => uid})

      assert Ueberauth.Strategy.Twitch.uid(conn) == uid
    end
  end

  describe "credentials" do
    test "are returned" do
      conn =
        %Plug.Conn{}
        |> Plug.Conn.put_private(:twitch_token, %{
          access_token: "access-token",
          refresh_token: "refresh-token",
          expires: false,
          expires_at: Time.utc_now(),
          other_params: %{}
        })

      creds = Ueberauth.Strategy.Twitch.credentials(conn)
      assert creds.token == "access-token"
      assert creds.refresh_token == "refresh-token"
      assert creds.expires == true
      assert creds.scopes == [""]
    end
  end

  describe "info" do
    test "is returned" do
      conn =
        %Plug.Conn{}
        |> Plug.Conn.put_private(:twitch_user, %{
          "display_name" => "JohnDoe",
          "email" => "johndoe@gmail.com",
          "login" => "johndoe",
          "description" => "My channel.",
          "profile_image_url" => "http://the.image.url",
        })

      info = Ueberauth.Strategy.Twitch.info(conn)
      assert info.name == "JohnDoe"
      assert info.nickname == "johndoe"
      assert info.email == "johndoe@gmail.com"
      assert info.description == "My channel."
      assert info.image == "http://the.image.url"
    end
  end
end
