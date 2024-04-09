defmodule SorgenfriWeb.ViewLive do
  use SorgenfriWeb, :live_view

  alias Sorgenfri.Accounts.Account
  alias Sorgenfri.Assets
  alias Sorgenfri.Assets.Asset
  alias Sorgenfri.Comments
  alias Sorgenfri.Comments.Comment
  alias Sorgenfri.Repo

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <div>
        <div :if={assigns[:prev]}>
          <%= @prev %>
        </div>
        <div :if={assigns[:next]}>
          <%= @next %>
        </div>
      </div>

      <figure>
        <img
          :if={@asset.kind == :image}
          src={~p"/uploads/#{@asset.hash}/original#{@asset.extension}"}
        />
        <video
          :if={@asset.kind == :video}
          controls
          src={~p"/uploads/#{@asset.hash}/original#{@asset.extension}"}
        >
        </video>
        <figcaption>
          <%= @asset.description %>
        </figcaption>
      </figure>

      <div>
        <article :for={comment <- @asset.comments}>
          <div class="font-semibold"><%= comment.user.name %>:</div>
          <div><%= comment.content %></div>
        </article>
      </div>
      <div>
        <.simple_form for={@comment_form} phx-change="validate" phx-submit="save">
          <.input field={@comment_form[:content]} label="Kommentar" />
          <:actions>
            <.button>Tilføj kommentar</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    {asset, around} = Assets.get_asset_and_around!(id)
    asset = Repo.preload(asset, comments: Comments.list_comments_query())

    changeset = change_comment(socket.assigns.current_user, asset)

    {:noreply,
     socket
     |> assign(:asset, asset)
     |> assign(parse_around(around, id))
     |> assign(:current_user, socket.assigns.current_user)
     |> assign_form(changeset)}
  end

  def parse_around(around, current_id) do
    case String.split(around, ".") do
      [prev, ^current_id] -> %{prev: prev}
      [^current_id, next] -> %{next: next}
      [prev, ^current_id, next] -> %{prev: prev, next: next}
      [^current_id] -> %{}
    end
  end

  @impl true
  def handle_event("validate", %{"comment" => comment_params}, socket) do
    changeset =
      change_comment(socket.assigns.current_user, socket.assigns.asset, comment_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"comment" => comment_params}, socket) do
    case Comments.create_comment(
           socket.assigns.current_user,
           socket.assigns.asset,
           comment_params
         ) do
      {:ok, _comment} ->
        asset =
          Repo.preload(socket.assigns.asset, [comments: Comments.list_comments_query()],
            force: true
          )

        changeset = change_comment(socket.assigns.current_user, socket.assigns.asset)

        {:noreply,
         socket
         |> assign(asset: asset)
         |> assign_form(changeset)
         |> put_flash(:info, "Kommentar tilføjet")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp change_comment(%Account{} = account, %Asset{} = asset, comment_params \\ %{}) do
    %Comment{user_id: account.user_id, asset_id: asset.id}
    |> Comments.change_comment(comment_params)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :comment_form, to_form(changeset))
  end
end
