defmodule OctosWeb.CameraJSON do
  alias Octos.Accounts.User
  alias Octos.Cameras.Camera

  @doc """
  Renders a list of users and its cameras.
  """
  def index(%{users: users, meta: %Flop.Meta{} = meta}) do
    %{users: Enum.map(users, &data/1), page: meta.current_page, total_pages: meta.total_pages}
  end

  defp data(%User{} = user) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      inactivation_date: user.inactivation_date,
      cameras: Enum.map(user.cameras, &data/1)
    }
  end

  defp data(%Camera{} = camera) do
    %{
      id: camera.id,
      brand: camera.brand,
      name: camera.name,
      active: camera.active
    }
  end
end
