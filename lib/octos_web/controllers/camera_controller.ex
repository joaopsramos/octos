defmodule OctosWeb.CameraController do
  use OctosWeb, :controller
  use Goal

  alias Octos.Accounts
  alias Octos.Cameras
  alias Octos.Cameras.Camera

  action_fallback OctosWeb.FallbackController

  @default_camera_to_notify Camera.hikvision()

  def index(conn, params) do
    with {:ok, params} <- validate(:index, params) do
      {users, meta} =
        Accounts.list_users_with_active_cameras(%{
          "filters" => [%{"field" => "name", "op" => "ilike", "value" => params[:name]}],
          "order_by" => [params.sort],
          "order_directions" => [params.direction],
          "page" => params.page,
          "page_size" => params.page_size
        })

      render(conn, :index, users: users, meta: meta)
    end
  end

  def notify(conn, params) do
    case Cameras.notify_users_by_brand(params["brand"] || @default_camera_to_notify) do
      :ok -> send_resp(conn, 200, "")
      {:error, reason} -> json(conn, %{error: reason})
    end
  end

  defparams :index do
    optional(:name, :string)
    optional(:sort, :enum, values: ["name"], default: :name)
    optional(:direction, :enum, values: ["asc", "desc"], default: :asc)
    optional(:page, :integer, min: 1, default: 1)
    optional(:page_size, :integer, min: 1, max: 100, default: 50)
  end
end
