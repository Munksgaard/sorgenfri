defmodule SorgenfriWeb.Admin.User.FormComponent do
  @moduledoc """
  A form component for updating users.
  """

  use SorgenfriWeb, :live_component

  alias Sorgenfri.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Redigér bruger
      </.header>

      <.list>
        <:item title="ID"><%= @user.id %></:item>
        <:item title="Navn"><%= @user.name %></:item>
        <:item title="Email"><%= @user.account.email %></:item>
        <:item title="Navn"><%= @user.name %></:item>
        <:item title="Accepted?"><%= @user.account.accepted %></:item>
        <:item title="Role"><%= @user.account.role %></:item>
      </.list>

      <hr class="h-px my-8 bg-gray-200 border-0 dark:bg-gray-700" />

      <.header>Handlinger</.header>

      <.button :if={not @user.account.accepted} phx-click="accept" phx-target={@myself}>
        Acceptér
      </.button>

      <.button :if={@user != @current_user} phx-click="delete" phx-target={@myself}>
        Slet
      </.button>

      <.button :if={not Accounts.admin?(@user)} phx-click="make-admin" phx-target={@myself}>
        Gør til administrator
      </.button>

      <.button
        :if={Accounts.admin?(@user) and @user != @current_user}
        phx-click="unmake-admin"
        phx-target={@myself}
      >
        Fjern som administrator
      </.button>
    </div>
    """
  end

  @impl true
  def handle_event("accept", _params, socket) do
    {:ok, account} = Accounts.accept(socket.assigns.user.account)
    user = %{socket.assigns.user | account: account}
    notify_parent({:saved, user})
    {:noreply, assign(socket, user: user)}
  end

  def handle_event("delete", _params, socket) do
    {:ok, %{user: user}} = Accounts.delete(socket.assigns.user)
    notify_parent({:deleted, user})

    {:noreply,
     socket
     |> assign(user: user)
     |> push_patch(to: socket.assigns.patch)}
  end

  def handle_event("make-admin", _params, socket) do
    {:ok, account} = Accounts.make_admin(socket.assigns.user.account)

    user = %{socket.assigns.user | account: account}
    notify_parent({:saved, user})
    {:noreply, assign(socket, user: user)}
  end

  def handle_event("unmake-admin", _params, socket) do
    {:ok, account} = Accounts.unmake_admin(socket.assigns.user.account)

    user = %{socket.assigns.user | account: account}
    notify_parent({:saved, user})
    {:noreply, assign(socket, user: user)}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
