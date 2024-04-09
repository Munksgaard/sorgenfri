defmodule Sorgenfri.Workers.VideoTranscoder do
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
            "extension" => _extension,
            "filename" => _filename,
            "user_id" => _user_id,
            "params" => _params
          } = args
      }) do
    with {:ok, asset_dir} <- get_asset_dir(),
         :ok <- create_webm(asset_dir, dest, hash),
         :ok <- create_thumbnail(asset_dir, dest, hash),
         {:ok, _asset} <- insert_asset(args) do
      :ok = Endpoint.broadcast("transcode", "complete", %{hash: hash})

      :ok
    else
      {:error, _} = error -> error
    end
  end

  defp get_asset_dir do
    with {:ok, env} <- Application.fetch_env(:sorgenfri, Sorgenfri.Uploads) do
      if asset_dir = env[:upload_dir] do
        {:ok, asset_dir}
      else
        {:error, :asset_dir_not_set}
      end
    else
      :error -> {:error, :fetch_env_failed}
    end
  end

  def create_webm(asset_dir, dest, hash) do
    import FFmpex
    use FFmpex.Options

    full_path = Path.join([asset_dir, hash, "full.webm"])

    command =
      FFmpex.new_command()
      |> add_global_option(option_y())
      |> add_input_file(dest)
      |> add_output_file("/dev/null")
      |> add_file_option(option_vf("scale=-1:700"))
      |> add_file_option(option_vcodec("libvpx-vp9"))
      |> add_file_option(option_pass("1"))
      |> add_file_option(option_an())
      |> add_file_option(option_f("null"))

    {:ok, ""} = execute(command)

    command =
      FFmpex.new_command()
      |> add_global_option(option_y())
      |> add_input_file(dest)
      |> add_output_file(full_path)
      |> add_file_option(option_vf("scale=-1:700"))
      |> add_file_option(option_vcodec("libvpx-vp9"))
      |> add_file_option(option_pass("2"))
      |> add_file_option(option_acodec("libopus"))

    {:ok, ""} = execute(command)

    :ok
  end

  defp create_thumbnail(asset_dir, dest, hash) do
    thumbnail_path = Path.join([asset_dir, hash, "thumb_180x180.webp"])

    Mogrify.open("#{dest}[0]")
    |> Mogrify.auto_orient()
    |> Mogrify.quality("90")
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
           kind: :video,
           user_id: params["user_id"]
         }
         |> Assets.change_asset(params["params"])
         |> Repo.insert() do
      {:error, error} -> {:error, {:insert_failed, error}}
      {:ok, _} = ok -> ok
    end
  end
end
