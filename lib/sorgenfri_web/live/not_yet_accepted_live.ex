defmodule SorgenfriWeb.NotYetAcceptedLive do
  use SorgenfriWeb, :live_view

  alias Sorgenfri.Accounts.Account
  alias Sorgenfri.Assets
  alias Sorgenfri.Assets.Asset
  alias Sorgenfri.Repo

  @impl true
  def render(assigns) do
    ~H"""
    Du har endnu ikke adgang til serveren. Vent på at en administrator accepterer dig.
    """
  end
end
