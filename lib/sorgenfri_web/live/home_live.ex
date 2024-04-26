defmodule SorgenfriWeb.HomeLive do
  use SorgenfriWeb, :live_view

  alias Sorgenfri.Accounts.Account
  alias Sorgenfri.Assets
  alias Sorgenfri.Assets.Asset
  alias Sorgenfri.Repo

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <div id="upload">
        <.simple_form for={@form} phx-change="validate" phx-submit="save">
          <label for={@uploads.asset.ref}>Image or video</label>
          <.live_file_input upload={@uploads.asset} />
          <.input field={@form[:description]} label="Beskrivelse" />
          <:actions>
            <.button>Tilføj</.button>
          </:actions>
        </.simple_form>

        <div :for={entry <- @uploads.asset.entries}>
          <figure>
            <.live_img_preview entry={entry} />
            <figcaption><%= entry.client_name %></figcaption>
          </figure>

          <%!-- entry.progress will update automatically for in-flight entries --%>
          <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>

          <%!-- a regular click event whose handler will invoke Phoenix.LiveView.cancel_upload/3 --%>
          <button
            type="button"
            phx-click="cancel-upload"
            phx-value-ref={entry.ref}
            aria-label="cancel"
          >
            &times;
          </button>

          <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
          <.error :for={err <- upload_errors(@uploads.asset, entry)}><%= to_string(err) %></.error>
        </div>
      </div>
      <div
        id="assets"
        phx-update="stream"
        phx-viewport-bottom={@meta.has_next_page? && "next-page"}
        phx-page-loading
        class={[
          "grid grid-cols-3 gap-4 justify-items-center",
          if(!@meta.has_next_page?, do: "pb-10", else: "pb-[calc(200vh)]")
        ]}
      >
        <.link :for={{dom_id, asset} <- @streams.assets} navigate={~p"/view/#{asset}"} id={dom_id}>
          <img loading="lazy" src={"/uploads/#{asset.hash}/thumb_180x180.webp"} />
        </.link>
      </div>
      <%= if @meta.has_next_page? do %>
        <div class="flex justify-center" phx-page-loading phx-viewport-bottom="next-page">
          Loading...
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {assets, meta} = Assets.list_assets!()

    changeset = change_asset(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:meta, meta)
     |> stream(:assets, assets)
     |> allow_upload(:asset,
       accept: ["video/*", "image/*"],
       max_file_size: 10_000_000_000,
       auto_upload: true
     )
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("next-page", _, socket) do
    {assets, meta} =
      socket.assigns.meta
      |> Flop.to_next_cursor()
      |> Assets.list_assets!()

    {:noreply,
     socket
     |> assign(:meta, meta)
     |> stream(:assets, assets)}
  end

  def handle_event("validate", %{"asset" => asset_params}, socket) do
    changeset =
      change_asset(socket.assigns.current_user, asset_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"asset" => asset_params}, socket) do
    entries =
      consume_uploaded_entries(
        socket,
        :asset,
        &consume_entry(socket.assigns.current_user, asset_params, &1, &2)
      )

    case entries do
      [{:invalid_changeset, changeset}] ->
        {:noreply, assign_form(socket, changeset)}

      [{:already_uploaded, _hash}] ->
        changeset = change_asset(socket.assigns.current_user)

        {:noreply,
         put_flash(socket, :error, "Den uploaded fil findes allerede") |> assign_form(changeset)}

      [{:ok, asset}] ->
        {:noreply,
         socket
         |> put_flash(:info, "Fil uploadet!")
         |> assign_form(change_asset(socket.assigns.current_user))
         |> stream_insert(:assets, asset, at: 0)}
    end
  end

  defp consume_entry(current_user, asset_params, %{path: path}, entry) do
    # You will need to create `priv/static/uploads` for `File.cp!/2` to work.
    hash = :crypto.hash(:sha256, File.read!(path)) |> Base.encode32(padding: false)

    asset_dir = Application.fetch_env!(:sorgenfri, Sorgenfri.Uploads)[:upload_dir]
    dest_dir = Path.join(asset_dir, hash)

    extension =
      entry.client_name
      |> Path.extname()

    dest = Path.join(dest_dir, "original#{extension}")

    changeset =
      Assets.change_asset(
        %Asset{
          filename: entry.client_name,
          hash: hash,
          kind: :image,
          user_id: current_user.id
        },
        asset_params
      )

    if changeset.valid? do
      case File.mkdir(dest_dir) do
        :ok ->
          File.cp!(path, dest)

          kind =
            case entry.client_type do
              <<"image/", _::binary>> ->
                :image

              <<"video/", _::binary>> ->
                :video
            end

          :ok =
            Assets.create_thumbnail(kind, dest, Path.join(dest_dir, "thumb_180x180.webp"))

          case %Asset{
                 extension: extension,
                 filename: entry.client_name,
                 hash: hash,
                 kind: kind,
                 user_id: current_user.id
               }
               |> Assets.change_asset(asset_params)
               |> Repo.insert() do
            {:error, error} -> {:postpone, {:insert_failed, error}}
            {:ok, asset} -> {:ok, {:ok, asset}}
          end

        {:error, :eexist} ->
          {:ok, {:already_uploaded, hash}}
      end
    else
      {:postpone, {:invalid_changeset, changeset}}
    end
  end

  defp change_asset(%Account{} = account, asset_params \\ %{}) do
    %Asset{user_id: account.user_id}
    |> Assets.change_asset(asset_params)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
