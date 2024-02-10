defmodule Sorgenfri.PasswordHashingNIF do
  use Rustler, otp_app: :sorgenfri, crate: :password_hashing

  def hash_password(_password), do: error()
  def verify_password(_password, _password_hash, _salt), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
