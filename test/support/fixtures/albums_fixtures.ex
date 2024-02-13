defmodule Sorgenfri.AlbumsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Sorgenfri.Albums` context.
  """

  @doc """
  Generate a album.
  """
  def album_fixture(attrs \\ %{}) do
    {:ok, album} =
      attrs
      |> Enum.into(%{
        date: 42,
        name: "some name"
      })
      |> Sorgenfri.Albums.create_album()

    album
  end
end
