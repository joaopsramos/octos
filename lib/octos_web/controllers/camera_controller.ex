defmodule OctosWeb.CameraController do
  use OctosWeb, :controller
  use Goal

  alias Octos.Accounts

  action_fallback OctosWeb.FallbackController

  def index(conn, params) do
    with {:ok, params} <- validate(:index, params) do
      {users, meta} =
        Accounts.list_users_with_active_cameras(%{
          "filters" => [%{"field" => "brand", "op" => "ilike", "value" => params[:brand]}],
          "order_by" => [params.sort],
          "order_directions" => [params.direction],
          "page" => params.page,
          "page_size" => params.page_size
        })

      render(conn, :index, users: users, meta: meta)
    end
  end

  defparams :index do
    optional(:brand, :string)
    optional(:sort, :enum, values: ["brand"], default: :brand)
    optional(:direction, :enum, values: ["asc", "desc"], default: :asc)
    optional(:page, :integer, min: 1, default: 1)
    optional(:page_size, :integer, min: 1, max: 100, default: 50)
  end
end
