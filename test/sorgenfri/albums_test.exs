defmodule Sorgenfri.AlbumsTest do
  use Sorgenfri.DataCase

  alias Sorgenfri.Albums

  describe "albums" do
    alias Sorgenfri.Albums.Album

    import Sorgenfri.AlbumsFixtures

    @invalid_attrs %{date: nil, name: nil}

    test "list_albums/0 returns all albums" do
      album = album_fixture()
      assert Albums.list_albums() == [album]
    end

    test "get_album!/1 returns the album with given id" do
      album = album_fixture()
      assert Albums.get_album!(album.id) == album
    end

    test "create_album/1 with valid data creates a album" do
      valid_attrs = %{date: 42, name: "some name"}

      assert {:ok, %Album{} = album} = Albums.create_album(valid_attrs)
      assert album.date == 42
      assert album.name == "some name"
    end

    test "create_album/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Albums.create_album(@invalid_attrs)
    end

    test "update_album/2 with valid data updates the album" do
      album = album_fixture()
      update_attrs = %{date: 43, name: "some updated name"}

      assert {:ok, %Album{} = album} = Albums.update_album(album, update_attrs)
      assert album.date == 43
      assert album.name == "some updated name"
    end

    test "update_album/2 with invalid data returns error changeset" do
      album = album_fixture()
      assert {:error, %Ecto.Changeset{}} = Albums.update_album(album, @invalid_attrs)
      assert album == Albums.get_album!(album.id)
    end

    test "delete_album/1 deletes the album" do
      album = album_fixture()
      assert {:ok, %Album{}} = Albums.delete_album(album)
      assert_raise Ecto.NoResultsError, fn -> Albums.get_album!(album.id) end
    end

    test "change_album/1 returns a album changeset" do
      album = album_fixture()
      assert %Ecto.Changeset{} = Albums.change_album(album)
    end
  end
end
