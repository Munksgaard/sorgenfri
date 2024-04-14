defmodule Sorgenfri.Workers.NewPhotoNotification do
  @moduledoc """
  An `Oban.Worker` that checks for new photos and sends out email notifications.
  """

  use Oban.Worker, queue: :email

  alias Sorgenfri.Accounts
  alias Sorgenfri.Assets
  alias Sorgenfri.Repo

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    if Assets.new_updates_last_day?() do
      accounts = Accounts.new_asset_notification_receivers() |> Repo.preload(:user)
    end
  end
end
