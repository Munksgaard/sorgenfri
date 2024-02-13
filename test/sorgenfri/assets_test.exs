defmodule Sorgenfri.AssetsTest do
  use Sorgenfri.DataCase

  alias Sorgenfri.Assets

  describe "assets" do
    alias Sorgenfri.Assets.Asset

    import Sorgenfri.AssetsFixtures

    @invalid_attrs %{
      date: nil,
      description: nil,
      extension: nil,
      filename: nil,
      hash: nil,
      kind: nil
    }

    test "list_assets/0 returns all assets" do
      asset = asset_fixture()
      assert Assets.list_assets() == [asset]
    end

    test "get_asset!/1 returns the asset with given id" do
      asset = asset_fixture()
      assert Assets.get_asset!(asset.id) == asset
    end

    test "create_asset/1 with valid data creates a asset" do
      valid_attrs = %{
        date: 42,
        description: "some description",
        extension: "some extension",
        filename: "some filename",
        hash: "some hash",
        kind: "some kind"
      }

      assert {:ok, %Asset{} = asset} = Assets.create_asset(valid_attrs)
      assert asset.date == 42
      assert asset.description == "some description"
      assert asset.extension == "some extension"
      assert asset.filename == "some filename"
      assert asset.hash == "some hash"
      assert asset.kind == "some kind"
    end

    test "create_asset/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Assets.create_asset(@invalid_attrs)
    end

    test "update_asset/2 with valid data updates the asset" do
      asset = asset_fixture()

      update_attrs = %{
        date: 43,
        description: "some updated description",
        extension: "some updated extension",
        filename: "some updated filename",
        hash: "some updated hash",
        kind: "some updated kind"
      }

      assert {:ok, %Asset{} = asset} = Assets.update_asset(asset, update_attrs)
      assert asset.date == 43
      assert asset.description == "some updated description"
      assert asset.extension == "some updated extension"
      assert asset.filename == "some updated filename"
      assert asset.hash == "some updated hash"
      assert asset.kind == "some updated kind"
    end

    test "update_asset/2 with invalid data returns error changeset" do
      asset = asset_fixture()
      assert {:error, %Ecto.Changeset{}} = Assets.update_asset(asset, @invalid_attrs)
      assert asset == Assets.get_asset!(asset.id)
    end

    test "delete_asset/1 deletes the asset" do
      asset = asset_fixture()
      assert {:ok, %Asset{}} = Assets.delete_asset(asset)
      assert_raise Ecto.NoResultsError, fn -> Assets.get_asset!(asset.id) end
    end

    test "change_asset/1 returns a asset changeset" do
      asset = asset_fixture()
      assert %Ecto.Changeset{} = Assets.change_asset(asset)
    end
  end
end
