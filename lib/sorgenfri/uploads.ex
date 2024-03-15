defmodule Sorgenfri.Uploads do
  def upload_dir do
    Application.fetch_env!(:sorgenfri, Sorgenfri.Uploads)[:upload_dir]
  end
end
