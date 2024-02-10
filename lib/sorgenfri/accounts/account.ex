defmodule Sorgenfri.Accounts.Account do
  use Sorgenfri.Schema
  import Ecto.Changeset

  alias Sorgenfri.PasswordHashingNIF

  schema "accounts" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true
    field :salt, :string, redact: true
    field :role, :string
    field :accepted, :boolean
    field :new_comment_notification, :boolean
    field :new_asset_notification, :boolean
    field :reset_token, :string
    field :reset_expiration, :utc_datetime
    field :date, :integer

    belongs_to :user, Leaf.Accounts.User
  end

  @doc """
  A account changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.
  """
  def registration_changeset(account, attrs) do
    account
    |> cast(attrs, [:email, :password])
    |> validate_email()
    |> validate_password()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email()
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password()
  end

  defp maybe_validate_unique_email(changeset) do
    changeset
    |> unsafe_validate_unique(:email, Sorgenfri.Repo)
    |> unique_constraint(:email)
  end

  defp maybe_hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      {:ok, {password_hash, salt}} = PasswordHashingNIF.hash_password(password)

      changeset
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:password_hash, password_hash)
      |> put_change(:salt, salt)
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Verifies the password.
  """
  def valid_password?(%__MODULE__{password_hash: password_hash, salt: salt}, password) do
    case PasswordHashingNIF.verify_password(password, password_hash, salt) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  @doc """
  A account changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(account, attrs) do
    account
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password()
  end

  @doc """
  A account changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(account, attrs) do
    account
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end
end
