# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :octos,
  ecto_repos: [Octos.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :octos, OctosWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: OctosWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Octos.PubSub,
  live_view: [signing_salt: "CqUj7K9o"]

config :octos, Oban,
  engine: Oban.Engines.Basic,
  queues: [default: 10, mailer: 5],
  repo: Octos.Repo,
  testing: :manual

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :octos, Octos.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :flop, repo: Octos.Repo

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
