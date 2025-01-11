defmodule Octos.Accounts do
  @moduledoc """
  Accounts context.
  """
  import Ecto.Query

  alias Octos.Accounts.User
  alias Octos.Cameras.Camera
  alias Octos.Repo

  @doc """
  Returns a paginated list of users with their active cameras.
  The cameras are filtered separately from the user pagination to ensure correct results.

  Params can be either a map of atom keys or string keys

  ## Parameters

    * `params` - A map containing:
      * `page` - The page number for user pagination
      * `page_size` - Number of users per page
      * Additional filter and sort parameters for cameras with Flop format

  ## Examples

      params = %{page: 1, page_size: 10, order_by: ["brand"], order_directions: ["asc"]}
      Accounts.list_users_with_active_cameras(params)
      {[%User{cameras: [%Camera{active: true}]}], %Flop.Meta{}}
  """
  @spec list_users_with_active_cameras(map()) :: {list(User.t()), Flop.Meta.t()}
  def list_users_with_active_cameras(params \\ %{}) do
    page_keys = ["page", "page_size", :page, :page_size]

    camera_flop =
      params |> Map.drop(page_keys) |> Flop.validate!(for: Camera, default_limit: false)

    preload_query = from(c in Camera, where: c.active) |> Flop.query(camera_flop)

    {results, meta} = Flop.validate_and_run!(User, Map.take(params, page_keys))

    {Repo.preload(results, cameras: preload_query), meta}
  end
end
