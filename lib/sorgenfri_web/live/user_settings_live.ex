defmodule SorgenfriWeb.UserSettingsLive do
  use SorgenfriWeb, :live_view

  alias Sorgenfri.Accounts

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Kontoindstillinger
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <div class="mt-4 font-semibold">Password</div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/accounts/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            field={@password_form[:email]}
            type="hidden"
            id="hidden_user_email"
            value={@current_email}
          />
          <.input field={@password_form[:password]} type="password" label="Nyt password" required />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Bekræft nyt password"
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Nuværende password"
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Skifter...">Skift Password</.button>
          </:actions>
        </.simple_form>
      </div>

      <div>
        <div class="mt-4 font-semibold">Notifikationer</div>
        <.simple_form
          for={@notification_form}
          id="notification_form"
          phx-change="validate_notifications"
          phx-submit="update_notifications"
        >
          <.input
            type="checkbox"
            field={@notification_form[:new_asset_notification]}
            label="Modtag e-mail notifikationer når der kommer nye billeder?"
          />
          <.input
            type="checkbox"
            field={@notification_form[:new_comment_notification]}
            label="Modtag e-mail notifikationer når der kommer kommentarer på et billede du har uploadet eller kommenteret på?"
          />
          <:actions>
            <.button phx-disable-with="Ændrer...">Ændr notifikationsindstillinger</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    account = socket.assigns.current_user
    password_changeset = Accounts.change_account_password(account)
    notification_changeset = Accounts.change_notifications(account)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, account.email)
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:notification_form, to_form(notification_changeset))

    {:ok, socket}
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "account" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_account_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "account" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_account_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_account_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("validate_notifications", params, socket) do
    %{"account" => account_params} = params

    notification_form =
      socket.assigns.current_user
      |> Accounts.change_notifications(account_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, notification_form: notification_form)}
  end

  def handle_event("update_notifications", params, socket) do
    %{"account" => account_params} = params
    account = socket.assigns.current_user

    case Accounts.update_notifications(account, account_params) do
      {:ok, account} ->
        notification_changeset = Accounts.change_notifications(account)

        {:noreply,
         socket
         |> assign(current_user: account)
         |> assign(notification_form: to_form(notification_changeset))
         |> put_flash(:info, "Notifikationsindstillinger opdateret")}

      {:error, changeset} ->
        {:noreply, assign(socket, notification_form: to_form(changeset))}
    end
  end
end
