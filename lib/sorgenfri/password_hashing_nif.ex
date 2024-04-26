defmodule Sorgenfri.PasswordHashingNIF.Macro do
  defmacro rustler_use() do
    use_precompiled = System.get_env("PRECOMPILED_NIF", "false")

    cond do
      use_precompiled == "true" or use_precompiled == "1" ->
        quote do
          use Rustler,
            otp_app: :sorgenfri,
            skip_compilation?: true,
            load_from: {:sorgenfri, "priv/native/libpassword_hashing"}
        end

      true ->
        quote do
          use Rustler,
            otp_app: :sorgenfri,
            crate: :password_hashing
        end
    end
  end
end

defmodule Sorgenfri.PasswordHashingNIF do
  require Sorgenfri.PasswordHashingNIF.Macro
  Sorgenfri.PasswordHashingNIF.Macro.rustler_use()

  def hash_password(_password), do: error()
  def verify_password(_password, _password_hash, _salt), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
