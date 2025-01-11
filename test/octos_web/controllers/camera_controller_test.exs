defmodule OctosWeb.CameraControllerTest do
  use OctosWeb.ConnCase, async: true
  use Oban.Testing, repo: Octos.Repo

  import Swoosh.TestAssertions

  alias Octos.Cameras.Camera
  alias Octos.Cameras.NotifyUserEmail

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists users with cameras", %{conn: conn} do
      insert_list(2, :user, cameras: build_list(3, :camera))

      conn = get(conn, ~p"/api/cameras")

      assert %{"page" => 1, "total_pages" => 1, "users" => users} = json_response(conn, 200)
      assert length(users) == 2

      for user <- users do
        assert length(user["cameras"]) == 3
      end
    end

    test "ensure correct fields", %{conn: conn} do
      inserted_user = insert(:user, cameras: [], inactivation_date: DateTime.utc_now())
      inserted_camera = insert(:camera, user_id: inserted_user.id)

      conn = get(conn, ~p"/api/cameras")

      assert %{"users" => [%{"cameras" => [camera]} = user]} = json_response(conn, 200)

      assert user["id"] == inserted_user.id
      assert user["name"] == inserted_user.name
      assert user["email"] == inserted_user.email
      assert user["inactivation_date"] == DateTime.to_iso8601(inserted_user.inactivation_date)

      assert camera["id"] == inserted_camera.id
      assert camera["brand"] == inserted_camera.brand
      assert camera["active"] == inserted_camera.active
    end

    test "can paginate", %{conn: conn} do
      insert_list(3, :user, cameras: build_list(3, :camera))

      conn = get(conn, ~p"/api/cameras", page: 2, page_size: 2)

      assert %{"page" => 2, "total_pages" => 2, "users" => [user]} = json_response(conn, 200)
      assert length(user["cameras"]) == 3
    end

    test "can filter by camera brand", %{conn: conn} do
      insert(:user, cameras: [build(:camera, brand: "Intelbras"), build(:camera, brand: "Giga")])

      conn = get(conn, ~p"/api/cameras", brand: "Giga")

      assert %{"users" => [%{"cameras" => [camera]}]} = json_response(conn, 200)
      assert camera["brand"] == "Giga"
    end

    test "can sort by camera brand", %{conn: conn} do
      insert(:user, cameras: [build(:camera, brand: "Intelbras"), build(:camera, brand: "Giga")])

      conn = get(conn, ~p"/api/cameras", sort: "brand", direction: "asc")

      assert %{"users" => [%{"cameras" => cameras}]} = json_response(conn, 200)
      assert Enum.map(cameras, & &1["brand"]) == ["Giga", "Intelbras"]

      conn = get(conn, ~p"/api/cameras", sort: "brand", direction: "desc")

      assert %{"users" => [%{"cameras" => cameras}]} = json_response(conn, 200)
      assert Enum.map(cameras, & &1["brand"]) == ["Intelbras", "Giga"]
    end

    test "uses default pagination", %{conn: conn} do
      insert_list(100, :user, cameras: build_list(2, :camera))

      conn = get(conn, ~p"/api/cameras")
      assert %{"page" => 1, "total_pages" => 2} = json_response(conn, 200)
    end

    test "returns errors with invalid params", %{conn: conn} do
      insert_list(100, :user, cameras: build_list(2, :camera))

      conn =
        get(conn, ~p"/api/cameras", sort: "name", direction: "asc-desc", page: -1, page_size: 101)

      assert %{
               "errors" => %{
                 "direction" => ["is invalid"],
                 "page" => ["must be greater than or equal to 1"],
                 "page_size" => ["must be less than or equal to 100"],
                 "sort" => ["is invalid"]
               }
             } = json_response(conn, 422)
    end
  end

  describe "notify" do
    test "send emails to users by camera brand", %{conn: conn} do
      users = insert_list(2, :user, cameras: [build(:camera, brand: Camera.vivotek())])

      Oban.Testing.with_testing_mode(:inline, fn ->
        conn = post(conn, ~p"/api/notify-users", brand: Camera.vivotek())

        for user <- users do
          user
          |> NotifyUserEmail.notify(Camera.vivotek())
          |> assert_email_sent()
        end

        assert response(conn, 200) == ""
      end)
    end

    test "uses default brand", %{conn: conn} do
      users = insert_list(2, :user, cameras: [build(:camera, brand: Camera.hikvision())])

      Oban.Testing.with_testing_mode(:inline, fn ->
        conn = post(conn, ~p"/api/notify-users")

        for user <- users do
          user
          |> NotifyUserEmail.notify(Camera.hikvision())
          |> assert_email_sent()
        end

        assert response(conn, 200) == ""
      end)
    end
  end
end
