defmodule SorgenfriWeb.NotYetAcceptedLive do
  use SorgenfriWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    Du har endnu ikke adgang til serveren. Vent på at en administrator accepterer dig.
    """
  end
end
