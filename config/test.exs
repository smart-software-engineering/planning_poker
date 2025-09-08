import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :planning_poker, PlanningPoker.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "planning_poker_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :planning_poker, PlanningPokerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "rESY86j4IKohlCKYAFP2WiIjciQwsxVU6kzjsFISWk92ss6R+u0IOTg2BouP03Xv",
  server: false

# In test we don't send emails
config :planning_poker, PlanningPoker.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Use mock implementation for user tracking in tests
config :planning_poker, :user_tracking_impl, PlanningPoker.UserTrackingMock

# Disable Sentry in test
config :sentry,
  dsn: nil,
  environment_name: :test,
  client: RateCalculator.SentryReqClient
