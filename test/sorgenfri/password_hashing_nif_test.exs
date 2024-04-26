defmodule Sorgenfri.PasswordHashingNIFTest do
  use Sorgenfri.DataCase

  alias Sorgenfri.PasswordHashingNIF

  describe "verify_password/3" do
    test "should return :ok for valid password" do
      assert {:ok, {}} =
               PasswordHashingNIF.verify_password(
                 "yrsadrengen",
                 "TnOIqxyhoyXBqqLX5uSJfiWhD7XTukVDZhaUZgtJi3zePKFHZOMWd8g6xODMCt/WJ+OOtJIJrdZW8iClsahqPw==",
                 "QuJ+GhS2jFGO9znM6TCU32ywcgZ7RBsm5pqFk3F7j5edkiTj2K4KjMxZ/vWAASnGp90eNScXGpXPQGAh/aZ5BQ=="
               )
    end

    test "should return :error for invalid password" do
      assert {:error, "Could not verify password"} =
               PasswordHashingNIF.verify_password(
                 "yrsadreng",
                 "TnOIqxyhoyXBqqLX5uSJfiWhD7XTukVDZhaUZgtJi3zePKFHZOMWd8g6xODMCt/WJ+OOtJIJrdZW8iClsahqPw==",
                 "QuJ+GhS2jFGO9znM6TCU32ywcgZ7RBsm5pqFk3F7j5edkiTj2K4KjMxZ/vWAASnGp90eNScXGpXPQGAh/aZ5BQ=="
               )
    end
  end
end
