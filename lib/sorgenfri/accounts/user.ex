defmodule Sorgenfri.Accounts.User do
  use Sorgenfri.Schema
  import Ecto.Changeset

  alias Sorgenfri.Accounts.Account

  schema "users" do
    field :name, :string
    field :date, :integer

    has_one :account, Leaf.Accounts.Account
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> cast_assoc(:account, with: Account.registration_changeset() / 2)
  end

  @doc """
  A user changeset for changing the password.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [])
    |> cast_assoc(:account, with: Account.password_changeset() / 2)
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [])
    |> cast_assoc(:account, with: Account.email_changeset() / 2)
  end
end
