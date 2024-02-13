defmodule Sorgenfri.Albums.Album do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sorgenfri.Accounts.User
  alias Sorgenfri.Assets.Asset

  schema "albums" do
    field :date, :integer
    field :name, :string

    has_many :assets, Asset

    belongs_to :user, User
  end

  @doc false
  def changeset(album, attrs) do
    album
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
