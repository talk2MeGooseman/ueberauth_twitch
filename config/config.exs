use Mix.Config

if Mix.env() == :test do
  config :ueberauth, Ueberauth,
    providers: [
      twitch: {Ueberauth.Strategy.Twitch, [default_scope: "user:read:email"]}
    ]

  config :ueberauth, Ueberauth.Strategy.Twitch.OAuth,
    client_id: System.get_env("TWITCH_CLIENT_ID") || "test_client_id",
    client_secret: System.get_env("TWITCH_CLIENT_SECRET") || "test_client_secret"
end
