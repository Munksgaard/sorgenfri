defmodule Sorgenfri.Util do
  @moduledoc """
  Various utility functions.
  """

  defp path_from_credentials_dir(name) do
    if credentials_directory = System.get_env("CREDENTIALS_DIRECTORY") do
      path =
        Path.join(credentials_directory, name)

      if File.regular?(path) do
        path
      else
        nil
      end
    else
      nil
    end
  end

  @doc ~S"""
  Supports reading secrets from a CREDENTIALS_DIRECTORY, as specified by systemd.

  More information: https://systemd.io/CREDENTIALS/
  """
  @spec get_secret(String.t()) :: String.t() | nil
  def get_secret(name) when is_binary(name) do
    cond do
      credentials_path = path_from_credentials_dir(name) ->
        File.read!(credentials_path)

      secret = System.get_env("#{name}") ->
        secret

      true ->
        nil
    end
  end
end
