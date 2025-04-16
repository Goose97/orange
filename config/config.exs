import Config

config :opentelemetry, traces_exporter: :none

import_config "#{config_env()}.exs"
