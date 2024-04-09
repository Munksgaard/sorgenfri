defmodule SorgenfriWeb.Router do
  use SorgenfriWeb, :router

  import SorgenfriWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SorgenfriWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Other scopes may use custom stacks.
  # scope "/api", SorgenfriWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:sorgenfri, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SorgenfriWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", SorgenfriWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{SorgenfriWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/accounts/register", UserRegistrationLive, :new
      live "/accounts/log_in", UserLoginLive, :new
      live "/accounts/reset_password", UserForgotPasswordLive, :new
      live "/accounts/reset_password/:token", AccountResetPasswordLive, :edit
    end

    post "/accounts/log_in", UserSessionController, :create
  end

  scope "/", SorgenfriWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{SorgenfriWeb.UserAuth, :ensure_authenticated}] do
      live "/", HomeLive
      live "/view/:id", ViewLive
      live "/accounts/settings", UserSettingsLive, :edit
      live "/accounts/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", SorgenfriWeb do
    pipe_through [:browser, :require_authenticated_user, :require_admin_user]

    live_session :require_admin_user,
      on_mount: [
        {SorgenfriWeb.UserAuth, :ensure_authenticated},
        {SorgenfriWeb.UserAuth, :ensure_admin}
      ] do
      live "/admin", AdminLive
    end
  end

  scope "/", SorgenfriWeb do
    pipe_through [:browser]

    delete "/accounts/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{SorgenfriWeb.UserAuth, :mount_current_user}] do
      live "/accounts/confirm/:token", UserConfirmationLive, :edit
      live "/accounts/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
