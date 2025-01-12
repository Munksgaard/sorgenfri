defmodule Sorgenfri.Assets do
  @moduledoc """
  The Assets context.
  """

  require Logger

  import Ecto.Query, warn: false
  alias Sorgenfri.Repo

  alias Sorgenfri.Assets.Asset

  @doc """
  Returns the list of assets.

  ## Examples

      iex> list_assets()
      [%Asset{}, ...]

  """
  def list_assets!(params \\ %{}) do
    Flop.validate_and_run!(Asset, params, for: Asset)
  end

  @doc """
  Gets a single asset.

  Raises `Ecto.NoResultsError` if the Asset does not exist.

  ## Examples

      iex> get_asset!(123)
      %Asset{}

      iex> get_asset!(456)
      ** (Ecto.NoResultsError)

  """
  def get_asset!(id), do: Repo.get!(Asset, id)

  def get_asset_and_around!(id) do
    subquery =
      from a in Asset,
        select: %{
          a_id: a.id,
          around:
            over(fragment("group_concat(?, '.')", a.id),
              order_by: fragment("date rows between 1 preceding and 1 following")
            )
        }

    query =
      from s in subquery(subquery),
        join: a in Asset,
        on: s.a_id == a.id,
        where: s.a_id == ^id,
        limit: 1,
        select: {a, s.around}

    Repo.one!(query)
  end

  @doc """
  Creates a asset.

  ## Examples

      iex> create_asset(%{field: value})
      {:ok, %Asset{}}

      iex> create_asset(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_asset(attrs \\ %{}) do
    %Asset{}
    |> Asset.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a asset.

  ## Examples

      iex> update_asset(asset, %{field: new_value})
      {:ok, %Asset{}}

      iex> update_asset(asset, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_asset(%Asset{} = asset, attrs) do
    asset
    |> Asset.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a asset.

  ## Examples

      iex> delete_asset(asset)
      {:ok, %Asset{}}

      iex> delete_asset(asset)
      {:error, %Ecto.Changeset{}}

  """
  def delete_asset(%Asset{} = asset) do
    Repo.delete(asset)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking asset changes.

  ## Examples

      iex> change_asset(asset)
      %Ecto.Changeset{data: %Asset{}}

  """
  def change_asset(%Asset{} = asset, attrs \\ %{}) do
    Asset.changeset(asset, attrs)
  end

  def new_updates_last_day? do
    query =
      from a in Asset,
        where: a.date > fragment("unixepoch(?)", from_now(-1, "day"))

    Repo.exists?(query)
  end

  def create_thumbnail(:video, source, destination) do
    case System.cmd(
           "ffmpeg",
           ~w(-ss 0 -i #{source} -frames:v 1 -filter:v yadif,scale=180:180:force_original_aspect_ratio=increase,crop=180:180 #{destination})
         ) do
      {_output, 0} ->
        Logger.info(%{
          msg: :thumbnail_created,
          type: :video,
          source: source,
          destination: destination
        })

        :ok

      {output, n} ->
        Logger.error(%{
          msg: :thumbnail_creation_failed,
          type: :video,
          source: source,
          destination: destination,
          error_code: n,
          output: output
        })

        {:error, :thumbnail_creation_failed}
    end
  end

  def create_thumbnail(:image, source, destination) do
    case System.cmd(
           "magick",
           ~w(#{source} -thumbnail 180x180^ -gravity center -extent 180x180 #{destination})
         ) do
      {_output, 0} ->
        Logger.info(%{
          msg: :thumbnail_created,
          type: :image,
          source: source,
          destination: destination
        })

        :ok

      {output, n} ->
        Logger.error(%{
          msg: :thumbnail_creation_failed,
          type: :image,
          source: source,
          destination: destination,
          error_code: n,
          output: output
        })

        {:error, :thumbnail_creation_failed}
    end
  end
end
