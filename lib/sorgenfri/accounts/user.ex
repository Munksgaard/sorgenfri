defmodule Sorgenfri.Accounts.User do
  use Sorgenfri.Schema
  import Ecto.Changeset

  alias Sorgenfri.Accounts.Account

  schema "users" do
    field :name, :string
    field :date, :integer

    has_one :account, Sorgenfri.Accounts.Account
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> cast_assoc(:account, with: &Account.registration_changeset(&1, &2, opts))
    |> unique_constraint(:name)
  end

  @doc """
  A user changeset for changing the password.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [])
    |> cast_assoc(:account, with: &Account.password_changeset(&1, &2, opts))
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [])
    |> cast_assoc(:account, with: &Account.email_changeset(&1, &2, opts))
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  @spec validate_current_password(Ecto.Changeset.t(), String.t()) :: Ecto.Changeset.t()
  def validate_current_password(%Ecto.Changeset{} = changeset, password) do
    if Account.valid_password?(changeset.data.account, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
