defmodule Sorgenfri.AssetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Sorgenfri.Assets` context.
  """

  @doc """
  Generate a asset.
  """
  def asset_fixture(attrs \\ %{}) do
    {:ok, asset} =
      attrs
      |> Enum.into(%{
        date: 42,
        description: "some description",
        extension: "some extension",
        filename: "some filename",
        hash: "some hash",
        kind: "some kind"
      })
      |> Sorgenfri.Assets.create_asset()

    asset
  end
end
