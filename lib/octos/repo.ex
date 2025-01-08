defmodule Octos.Repo do
  use Ecto.Repo,
    otp_app: :octos,
    adapter: Ecto.Adapters.Postgres
end
