defmodule Octos.CamerasTest do
  use Octos.DataCase, async: true

  alias Octos.Cameras
  alias Octos.Cameras.Camera
  alias Octos.Cameras.Workers.NotifyUsers

  describe "notify_users_by_brand/1" do
    test "creates oban job with given brand" do
      assert :ok = Cameras.notify_users_by_brand(Camera.giga())
      assert_enqueued(worker: NotifyUsers, args: %{brand: Camera.giga()})
    end

    test "brand is normalized" do
      assert :ok = Cameras.notify_users_by_brand("giGA")
      assert_enqueued(worker: NotifyUsers, args: %{brand: Camera.giga()})
    end

    test "error with invalid brand" do
      assert {:error, "invalid brand"} = Cameras.notify_users_by_brand("some brand")
    end
  end
end
