defmodule SorgenfriWeb.AdminLive do
  use SorgenfriWeb, :live_view

  alias Sorgenfri.Accounts
  alias Sorgenfri.Repo

  def render(assigns) do
    ~H"""
    <.table id="users" rows={@streams.users}>
      <:col :let={{_, user}} label="id"><%= user.id %></:col>
      <:col :let={{_, user}} label="email"><%= user.account.email %></:col>
      <:col :let={{_, user}} label="name"><%= user.name %></:col>
      <:col :let={{_, user}} label="role"><%= user.account.role %></:col>
    </.table>
    """
  end

  def mount(params, session, socket) do
    users = Accounts.list_users() |> Repo.preload(:account)

    {:ok, stream(socket, :users, users)}
  end
end
