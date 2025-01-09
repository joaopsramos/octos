defmodule Octos.Cameras.CameraTest do
  use Octos.DataCase, async: true

  alias Octos.Cameras.Camera

  setup do
    user = insert(:user)
    valid_params = params_for(:camera, user_id: user.id)
    invalid_params = params_for(:camera, brand: "some other brand")

    %{user: user, valid_params: valid_params, invalid_params: invalid_params}
  end

  test "brands/0 returns all brands" do
    assert Camera.brands() == ["Intelbras", "Hikvision", "Giga", "Vivotek"]
  end

  for brand <- Camera.brands() do
    func_name = brand |> String.downcase() |> String.to_atom()

    test "#{func_name}/0 returns correct brand" do
      assert apply(Camera, unquote(func_name), []) == unquote(brand)
    end
  end

  describe "changeset/2" do
    test "with valid params returns valid changeset", ctx do
      changeset = Camera.changeset(%Camera{}, ctx.valid_params)

      assert changeset.valid?
    end

    test "with invalid params returns invalid changeset", ctx do
      changeset = Camera.changeset(%Camera{}, ctx.invalid_params)

      refute changeset.valid?
      assert %{brand: ["is invalid"], user_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "can be used to update a camera", ctx do
      changeset =
        :camera
        |> insert(brand: Camera.giga(), user_id: ctx.user.id)
        |> Camera.changeset(%{brand: Camera.intelbras()})

      assert changeset.changes == %{brand: Camera.intelbras()}
      assert changeset.valid?
    end
  end
end
