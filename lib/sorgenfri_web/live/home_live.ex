defmodule SorgenfriWeb.HomeLive do
  use SorgenfriWeb, :live_view

  alias Sorgenfri.Assets

  def render(assigns) do
    ~H"""
    <div class="space-y-8">
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
        <img
          :for={{dom_id, asset} <- @streams.assets}
          loading="lazy"
          src={"/assets/#{asset.hash}/thumb_180x180.webp"}
        />
      </div>
      <%= if @meta.has_next_page? do %>
        <div class="flex justify-center" phx-page-loading phx-viewport-bottom="next-page">
          Loading...
        </div>
      <% else %>
        🎉 You made it to the beginning of time 🎉
      <% end %>
    </div>
    """
  end

  def handle_params(_params, _uri, socket) do
    {assets, meta} = Assets.list_assets!()

    {:noreply,
     socket
     |> assign(:meta, meta)
     |> stream(:assets, assets)}
  end

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
end
