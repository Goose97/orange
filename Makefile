.PHONY: playground

playground:
	elixir --erl "-noinput" -S mix run playground/playground.exs
