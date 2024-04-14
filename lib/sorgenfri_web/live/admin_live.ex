defmodule SorgenfriWeb.AdminLive do
  use SorgenfriWeb, :live_view

  alias Sorgenfri.Accounts
  alias Sorgenfri.Repo

  @impl true
  def mount(params, session, socket) do
    users = Accounts.list_users() |> Repo.preload(:account)

    {:ok, stream(socket, :users, users)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit_user, %{"user_id" => id}) do
    user = Accounts.get_user!(id) |> Repo.preload(:account)

    assign(socket, :user, user)
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :file, nil)
  end

  @impl true
  def handle_info({SorgenfriWeb.Admin.User.FormComponent, {:saved, user}}, socket) do
    {:noreply, stream_insert(socket, :users, user)}
  end

  def handle_info({SorgenfriWeb.Admin.User.FormComponent, {:deleted, user}}, socket) do
    {:noreply, stream_delete(socket, :users, user)}
  end
end
