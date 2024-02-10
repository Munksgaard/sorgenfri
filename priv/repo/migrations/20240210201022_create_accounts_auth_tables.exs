defmodule Sorgenfri.Repo.Migrations.CreateAccountsAuthTables do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :email, :string, null: false, collate: :nocase
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:accounts, [:email])

    create table(:accounts_tokens) do
      add :user_id, references(:accounts, on_delete: :delete_all), null: false
      add :token, :binary, null: false, size: 32
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:accounts_tokens, [:user_id])
    create unique_index(:accounts_tokens, [:context, :token])
  end
end
