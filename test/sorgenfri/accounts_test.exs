defmodule Sorgenfri.AccountsTest do
  use Sorgenfri.DataCase

  alias Sorgenfri.Accounts

  import Sorgenfri.AccountsFixtures
  alias Sorgenfri.Accounts.{User, Account, AccountToken}

  describe "get_account_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_account_by_email("unknown@example.com")
    end

    test "returns the account if the email exists" do
      %{account: %{id: id}} = user = user_fixture()

      assert %Account{id: ^id} = Accounts.get_account_by_email(user.account.email)
    end
  end

  describe "get_account_by_email_and_password/2" do
    test "does not return the account if the email does not exist" do
      refute Accounts.get_account_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the account if the password is not valid" do
      user = user_fixture()
      refute Accounts.get_account_by_email_and_password(user.account.email, "invalid")
    end

    test "returns the account if the email and password are valid" do
      %{account: %{id: id}} = user = user_fixture()

      assert %Account{id: ^id} =
               Accounts.get_account_by_email_and_password(
                 user.account.email,
                 valid_user_password()
               )
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{
               name: ["can't be blank"],
               account: ["can't be blank"]
             } =
               errors_on(changeset)

      {:error, changeset} = Accounts.register_user(%{account: %{}})

      assert %{
               name: ["can't be blank"],
               account: %{password: ["can't be blank"], email: ["can't be blank"]}
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} =
        Accounts.register_user(%{name: "", account: %{email: "not valid", password: "not"}})

      assert %{
               name: ["can't be blank"],
               account: %{
                 email: ["must have the @ sign and no spaces"],
                 password: ["should be at least 4 character(s)"]
               }
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.register_user(%{account: %{email: too_long, password: too_long}})

      assert "should be at most 160 character(s)" in errors_on(changeset).account.email
      assert "should be at most 72 character(s)" in errors_on(changeset).account.password
    end

    test "validates email uniqueness" do
      %{account: %{email: email}} = user_fixture()
      {:error, changeset} = Accounts.register_user(%{account: %{email: email, password: "asdf"}})
      assert "has already been taken" in errors_on(changeset).account.email
    end

    test "validates name uniqueness" do
      %{name: name} = user_fixture()

      {:error, changeset} =
        Accounts.register_user(%{
          name: name,
          account: %{email: unique_user_email(), password: "valid password"}
        })

      assert "has already been taken" in errors_on(changeset).name
    end

    test "registers accounts with a hashed password" do
      email = unique_user_email()

      {:ok, user} =
        Accounts.register_user(
          valid_user_attributes(account: %{email: email, password: "valid password"})
        )

      assert user.account.email == email
      assert is_binary(user.account.password_hash)
      assert is_nil(user.account.password)
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{})
      assert changeset.required == [:name, :account]
    end

    test "allows fields to be set" do
      name = unique_user_name()
      email = unique_user_email()
      password = valid_user_password()

      changeset =
        Accounts.change_user_registration(
          %User{},
          valid_user_attributes(name: name, account: %{email: email, password: password})
        )

      assert changeset.valid?
      assert get_change(changeset, :name) == name

      account_changeset = get_change(changeset, :account)
      assert get_change(account_changeset, :email) == email
      assert get_change(account_changeset, :password) == password
      assert is_nil(get_change(account_changeset, :password_hash))
    end
  end

  describe "change_account_password/2" do
    test "returns a account changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_account_password(%Account{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_account_password(%Account{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :password_hash))
    end
  end

  describe "update_account_password/3" do
    setup do
      %{account: user_fixture().account}
    end

    test "validates password", %{account: account} do
      {:error, changeset} =
        Accounts.update_account_password(account, valid_user_password(), %{
          password: "not",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 4 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{account: account} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_account_password(account, valid_user_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{account: account} do
      {:error, changeset} =
        Accounts.update_account_password(account, "invalid", %{password: valid_user_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{account: account} do
      {:ok, account} =
        Accounts.update_account_password(account, valid_user_password(), %{
          password: "new valid password"
        })

      assert is_nil(account.password)
      assert Accounts.get_account_by_email_and_password(account.email, "new valid password")
    end

    test "deletes all tokens for the given account", %{account: account} do
      _ = Accounts.generate_account_session_token(account)

      {:ok, _} =
        Accounts.update_account_password(account, valid_user_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(AccountToken, account_id: account.id)
    end
  end

  describe "generate_account_session_token/1" do
    setup do
      %{account: user_fixture().account}
    end

    test "generates a token", %{account: account} do
      token = Accounts.generate_account_session_token(account)
      assert account_token = Repo.get_by(AccountToken, token: token)
      assert account_token.context == "session"

      # Creating the same token for another account should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%AccountToken{
          token: account_token.token,
          account_id: user_fixture().account.id,
          context: "session"
        })
      end
    end
  end

  describe "get_account_by_session_token/1" do
    setup do
      account = user_fixture().account
      token = Accounts.generate_account_session_token(account)
      %{account: account, token: token}
    end

    test "returns account by token", %{account: account, token: token} do
      assert session_account = Accounts.get_account_by_session_token(token)
      assert session_account.id == account.id
    end

    test "does not return account for invalid token" do
      refute Accounts.get_account_by_session_token("oops")
    end

    test "does not return account for expired token", %{token: token} do
      {1, nil} = Repo.update_all(AccountToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_account_by_session_token(token)
    end
  end

  describe "delete_account_session_token/1" do
    test "deletes the token" do
      account = user_fixture().account
      token = Accounts.generate_account_session_token(account)
      assert Accounts.delete_account_session_token(token) == :ok
      refute Accounts.get_account_by_session_token(token)
    end
  end

  describe "deliver_account_reset_password_instructions/2" do
    setup do
      %{account: user_fixture().account}
    end

    test "sends token through notification", %{account: account} do
      token =
        extract_account_token(fn url ->
          Accounts.deliver_account_reset_password_instructions(account, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert account_token = Repo.get_by(AccountToken, token: :crypto.hash(:sha256, token))
      assert account_token.account_id == account.id
      assert account_token.sent_to == account.email
      assert account_token.context == "reset_password"
    end
  end

  describe "get_account_by_reset_password_token/1" do
    setup do
      account = user_fixture().account

      token =
        extract_account_token(fn url ->
          Accounts.deliver_account_reset_password_instructions(account, url)
        end)

      %{account: account, token: token}
    end

    test "returns the account with valid token", %{account: %{id: id}, token: token} do
      assert %Account{id: ^id} = Accounts.get_account_by_reset_password_token(token)
      assert Repo.get_by(AccountToken, account_id: id)
    end

    test "does not return the account with invalid token", %{account: account} do
      refute Accounts.get_account_by_reset_password_token("oops")
      assert Repo.get_by(AccountToken, account_id: account.id)
    end

    test "does not return the account if token expired", %{account: account, token: token} do
      {1, nil} = Repo.update_all(AccountToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_account_by_reset_password_token(token)
      assert Repo.get_by(AccountToken, account_id: account.id)
    end
  end

  describe "reset_account_password/2" do
    setup do
      %{account: user_fixture().account}
    end

    test "validates password", %{account: account} do
      {:error, changeset} =
        Accounts.reset_account_password(account, %{
          password: "not",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 4 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{account: account} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_account_password(account, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{account: account} do
      {:ok, updated_account} =
        Accounts.reset_account_password(account, %{password: "new valid password"})

      assert is_nil(updated_account.password)
      assert Accounts.get_account_by_email_and_password(account.email, "new valid password")
    end

    test "deletes all tokens for the given account", %{account: account} do
      _ = Accounts.generate_account_session_token(account)
      {:ok, _} = Accounts.reset_account_password(account, %{password: "new valid password"})
      refute Repo.get_by(AccountToken, account_id: account.id)
    end
  end

  describe "inspect/2 for the Account module" do
    test "does not include password" do
      refute inspect(%Account{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
