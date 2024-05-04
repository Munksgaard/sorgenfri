defmodule Sorgenfri.Workers.NewPhotoNotification do
  @moduledoc """
  An `Oban.Worker` that checks for new photos and sends out email notifications.
  """

  use Oban.Worker, queue: :email

  require Logger

  alias Sorgenfri.Accounts
  alias Sorgenfri.Assets
  alias Sorgenfri.Repo

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    if Assets.new_updates_last_day?() do
      accounts = Accounts.new_asset_notification_receivers() |> Repo.preload(:user)

      for account <- accounts do
        try do
          case Accounts.AccountNotifier.deliver_new_photo_notification(account) do
            {:ok, _} ->
              :ok

            {:error, e} ->
              Logger.notice(%{type: :new_photo_noficiation_failed, error: e})
              {:ok, _} = Accounts.disable_email_notifications(account)
          end
        rescue
          e ->
            Logger.error(Exception.format(:error, e, __STACKTRACE__))
            :ok
        end
      end

      {:ok, {:notifications_sent, length(accounts)}}
    else
      {:ok, :no_new_assets}
    end
  end
end
