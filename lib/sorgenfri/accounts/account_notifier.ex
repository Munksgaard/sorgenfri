defmodule Sorgenfri.Accounts.AccountNotifier do
  import Swoosh.Email

  alias Sorgenfri.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Sorgenfri", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(account, url) do
    deliver(account.email, "Confirmation instructions", """

    ==============================

    Hi #{account.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a account password.
  """
  def deliver_reset_password_instructions(account, url) do
    deliver(account.email, "Reset password instructions", """

    ==============================

    Hi #{account.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a account email.
  """
  def deliver_update_email_instructions(account, url) do
    deliver(account.email, "Update email instructions", """

    ==============================

    Hi #{account.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver notification about new uploads.
  """
  def deliver_new_photo_notification(account) do
    deliver(account.email, "Nye billeder i Ebbes fotoalbum", """
    Kære #{account.user.name},

    Der er i dag blevet uploadet nye billeder i Ebbes fotoalbum. Se dem her: https://photos.munksgaard.me.

    Du kan afmelde disse notifikationer ved at gå til https://photos.munksgaard.me/accounts/settings.

    Venlig hilsen
    Fotoalbummet
    """)
  end
end
