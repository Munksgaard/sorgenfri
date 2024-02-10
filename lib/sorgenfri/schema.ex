defmodule Sorgenfri.Schema do
  @moduledoc """
  The base schema for the `Sorgenfri` app.

  The purpose of this schema is to use utc_datetime for timestamps by default.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      @timestamps_opts [type: :utc_datetime_usec]
    end
  end
end
