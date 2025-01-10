defmodule Octos.AccountsTest do
  use Octos.DataCase, async: true

  alias Octos.Accounts
  alias Octos.Accounts.User

  describe "list_users_with_active_cameras/1" do
    test "return only active cameras" do
      insert(:user, cameras: [build(:camera, active: false), build(:camera, active: true)])

      {[%User{cameras: [camera]}], _meta} = Accounts.list_users_with_active_cameras()

      assert camera.active
    end

    test "accept params" do
      insert(:user, cameras: [build(:camera, brand: "Intelbras"), build(:camera, brand: "Giga")])

      {[%User{cameras: [camera]}], _meta} =
        Accounts.list_users_with_active_cameras(%{
          filters: [%{field: "brand", op: "ilike", value: "giGA"}]
        })

      assert camera.brand == "Giga"
    end

    test "can paginate results not affecting cameras count" do
      insert_list(3, :user, cameras: build_list(3, :camera))

      {[%User{cameras: cameras1}, %User{cameras: cameras2}], %Flop.Meta{} = meta} =
        Accounts.list_users_with_active_cameras(%{page: 1, page_size: 2})

      assert length(cameras1) == 3
      assert length(cameras2) == 3

      assert meta.total_pages == 2
      assert meta.current_page == 1

      {[%User{cameras: cameras3}], %Flop.Meta{current_page: 2}} =
        Accounts.list_users_with_active_cameras(%{page: 2, page_size: 2})

      assert length(cameras3) == 3
    end
  end
end
