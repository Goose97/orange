import Config

config :logger, backends: [{LoggerFileBackend, :file_log}]

config :logger, :file_log,
  path: "log/orange.log",
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

import_config "#{config_env()}.exs"
