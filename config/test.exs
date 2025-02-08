import Config

IO.puts("MIX_ENV: #{Mix.env()}")

config :rustler_precompiled, force_build_all: true
