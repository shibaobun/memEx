defmodule MemexWeb.Router do
  use MemexWeb, :router
  import Phoenix.LiveDashboard.Router
  import MemexWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {MemexWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :put_user_locale
  end

  pipeline :require_admin do
    plug :require_role, role: :admin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MemexWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", MemexWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    delete "/users/settings/:id", UserSettingsController, :delete
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
    get "/export/:mode", ExportController, :export

    live_session :default, on_mount: [{MemexWeb.UserAuth, :ensure_authenticated}] do
      live "/notes/new", NoteLive.Index, :new
      live "/notes/:slug/edit", NoteLive.Index, :edit
      live "/note/:slug/edit", NoteLive.Show, :edit

      live "/contexts/new", ContextLive.Index, :new
      live "/contexts/:slug/edit", ContextLive.Index, :edit
      live "/context/:slug/edit", ContextLive.Show, :edit

      live "/pipelines/new", PipelineLive.Index, :new
      live "/pipelines/:slug/edit", PipelineLive.Index, :edit
      live "/pipeline/:slug/edit", PipelineLive.Show, :edit
      live "/pipeline/:slug/add_step", PipelineLive.Show, :add_step
      live "/pipeline/:slug/:step_id", PipelineLive.Show, :edit_step
    end
  end

  scope "/", MemexWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm

    live_session :public, on_mount: [{MemexWeb.UserAuth, :mount_current_user}] do
      live "/", HomeLive
      live "/faq", FaqLive

      live "/notes", NoteLive.Index, :index
      live "/notes/:search", NoteLive.Index, :search
      live "/note/:slug", NoteLive.Show, :show

      live "/contexts", ContextLive.Index, :index
      live "/contexts/:search", ContextLive.Index, :search
      live "/context/:slug", ContextLive.Show, :show

      live "/pipelines", PipelineLive.Index, :index
      live "/pipelines/:search", PipelineLive.Index, :search
      live "/pipeline/:slug", PipelineLive.Show, :show
    end
  end

  scope "/", MemexWeb do
    pipe_through [:browser, :require_authenticated_user, :require_admin]

    live_dashboard "/dashboard", metrics: MemexWeb.Telemetry, ecto_repos: [Memex.Repo]

    live_session :admin, on_mount: [{MemexWeb.UserAuth, :ensure_admin}] do
      live "/invites", InviteLive.Index, :index
      live "/invites/new", InviteLive.Index, :new
      live "/invites/:id/edit", InviteLive.Index, :edit
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
      get "/preview/:id", MemexWeb.EmailController, :preview
    end
  end
end
