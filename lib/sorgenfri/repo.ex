defmodule Sorgenfri.Repo do
  use Ecto.Repo,
    otp_app: :sorgenfri,
    adapter: Ecto.Adapters.SQLite3
end
