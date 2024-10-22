defmodule SorgenfriWeb.UserRegistrationLiveTest do
  use SorgenfriWeb.ConnCase

  import Phoenix.LiveViewTest
  import Sorgenfri.AccountsFixtures

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/accounts/register")

      assert html =~ "Register"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/accounts/register")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/accounts/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(
          user: %{"name" => "", "account" => %{"email" => "with spaces", "password" => "too"}}
        )

      assert result =~ "Register"
      assert result =~ "be blank"
      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 4 character"
    end
  end

  describe "register user" do
    test "creates account and logs the user in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/accounts/register")

      email = unique_user_email()

      form =
        form(lv, "#registration_form",
          user: valid_user_attributes(account: %{email: email, password: "valid password"})
        )

      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ email
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/accounts/register")

      user = user_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          user: %{"account" => %{"email" => user.account.email, "password" => "valid_password"}}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end

    test "renders errors for duplicated name", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/accounts/register")

      user = user_fixture(%{name: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          user: %{
            "name" => user.name,
            "account" => %{"email" => unique_user_email(), "password" => "valid_password"}
          }
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/accounts/register")

      {:ok, _login_live, login_html} =
        lv
        |> element(~s|main a:fl-contains("Sign in")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/accounts/log_in")

      assert login_html =~ "Log in"
    end
  end
end
