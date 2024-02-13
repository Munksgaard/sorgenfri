defmodule SorgenfriWeb.ViewLive do
  use SorgenfriWeb, :live_view

  alias Sorgenfri.Assets

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

        <figure>
          <img :if={@asset.kind == :image} src={~p"/assets/#{@asset.hash}/full.webp"} />
          <video :if={@asset.kind == :video} controls src={~p"/assets/#{@asset.hash}/full.webm"}>
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
      </div>
    </div>
    """
  end

  def parse_around(around, current_id) do
    case String.split(around, ".") do
      [prev, ^current_id] -> %{prev: prev}
      [^current_id, next] -> %{next: next}
      [prev, ^current_id, next] -> %{prev: prev, next: next}
      [] -> %{}
    end
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    {asset, around} = Assets.get_asset_and_around!(id)

    {:noreply,
     socket
     |> assign(:asset, Sorgenfri.Repo.preload(asset, comments: :user))
     |> assign(parse_around(around, id))}
  end
end
