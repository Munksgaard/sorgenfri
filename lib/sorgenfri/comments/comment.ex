defmodule Sorgenfri.Comments.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :content, :string
    field :date, :integer

    belongs_to :asset, Sorgenfri.Assets.Asset
    belongs_to :user, Sorgenfri.Accounts.User
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end
end
