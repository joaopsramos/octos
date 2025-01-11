defmodule Octos.Cameras.NotifyUserEmail do
  @moduledoc """
  Module responsible for building emails to notify users about camera events.
  """
  import Swoosh.Email

  alias Octos.Accounts.User

  @spec notify(User.t(), String.t()) :: Swoosh.Email.t()
  def notify(user, camera_brand) do
    new()
    |> to({user.name, user.email})
    |> from({"octos", "octos@example.com"})
    |> subject("Notiication from your camera #{camera_brand}")
    |> html_body("<h1>Attempted home invasion</h1>")
    |> text_body("Attempted home invasion")
  end
end
