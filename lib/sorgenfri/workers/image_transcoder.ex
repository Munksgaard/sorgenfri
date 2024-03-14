defmodule Sorgenfri.Workers.ImageTranscoder do
  use Oban.Worker, queue: :transcoders, max_attempts: 1

  alias Sorgenfri.Assets
  alias Sorgenfri.Assets.Asset
  alias Sorgenfri.Endpoint
  alias Sorgenfri.Repo
  alias SorgenfriWeb.Endpoint

  @impl Oban.Worker
  def perform(%Oban.Job{
        args:
          %{
            "dest" => dest,
            "hash" => hash,
            "kind" => "image",
            "extension" => _extension,
            "filename" => _filename,
            "user_id" => _user_id,
            "params" => _params
          } = args
      }) do
    with {:ok, asset_dir} <- get_asset_dir(),
         :ok <- create_webp(asset_dir, dest, hash),
         :ok <- create_thumbnail(asset_dir, dest, hash),
         {:ok, _asset} <- insert_asset(args) do
      :ok = Endpoint.broadcast("transcode", "complete", %{hash: hash})

      :ok
    else
      {:error, _} = error -> error
    end
  end

  defp get_asset_dir do
    with {:ok, env} <- Application.fetch_env(:sorgenfri, Sorgenfri.Assets) do
      if asset_dir = env[:asset_dir] do
        {:ok, asset_dir}
      else
        {:error, :asset_dir_not_set}
      end
    else
      :error -> {:error, :fetch_env_failed}
    end
  end

  defp create_webp(asset_dir, dest, hash) do
    full_path = Path.join([asset_dir, hash, "full.webp"])

    Mogrify.open(dest) |> Mogrify.auto_orient() |> Mogrify.save(path: full_path)

    :ok
  end

  defp create_thumbnail(asset_dir, dest, hash) do
    thumbnail_path = Path.join([asset_dir, hash, "thumb_180x180.webp"])

    Mogrify.open(dest)
    |> Mogrify.auto_orient()
    |> Mogrify.quality("60")
    |> Mogrify.custom("thumbnail", "180x180")
    |> Mogrify.gravity("center")
    |> Mogrify.extent("180x180")
    |> Mogrify.save(path: thumbnail_path)

    :ok
  end

  defp insert_asset(params) do
    case %Asset{
           extension: params["extension"],
           filename: params["filename"],
           hash: params["hash"],
           kind: :image,
           user_id: params["user_id"]
         }
         |> Assets.change_asset(params["params"])
         |> Repo.insert() do
      {:error, error} -> {:error, {:insert_failed, error}}
      {:ok, _} = ok -> ok
    end
  end
end
