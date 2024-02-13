defmodule Sorgenfri.Assets.Asset do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sorgenfri.Accounts.User
  alias Sorgenfri.Albums.Album
  alias Sorgenfri.Comments.Comment

  schema "assets" do
    field :date, :integer
    field :description, :string
    field :extension, :string
    field :filename, :string
    field :hash, :string

    field :kind, Ecto.Enum, values: [:image, :video]

    belongs_to :album, Album
    belongs_to :user, User

    has_many :comments, Comment
  end

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [:description])
    |> validate_required([:description])
  end
end
