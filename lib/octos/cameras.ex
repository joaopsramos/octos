defmodule Octos.Cameras do
  @moduledoc """
  Cameras context.
  """
  alias Octos.Cameras.Camera
  alias Octos.Cameras.Workers.NotifyUsers

  @doc """
  Send an email to all active users who have active cameras with the given brand
  """
  @spec notify_users_by_brand(String.t()) :: :ok | {:error, String.t()}
  def notify_users_by_brand(brand) do
    if brand = Enum.find(Camera.brands(), &(String.downcase(&1) == String.downcase(brand))) do
      %{"brand" => brand}
      |> NotifyUsers.new()
      |> Oban.insert!()

      :ok
    else
      {:error, "invalid brand"}
    end
  end
end
