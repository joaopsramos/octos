defmodule Octos.Accounts.UserTest do
  use Octos.DataCase, async: true

  alias Octos.Accounts.User

  setup do
    valid_params = params_for(:user)
    invalid_params = params_for(:user, name: nil, email: "invalid.email")

    %{valid_params: valid_params, invalid_params: invalid_params}
  end

  test "email is unique" do
    user = insert(:user)

    assert_raise Ecto.ConstraintError, fn ->
      insert(:user, email: user.email)
    end
  end

  describe "changeset/2" do
    test "with valid params returns valid changeset", ctx do
      changeset = User.changeset(%User{}, ctx.valid_params)

      assert changeset.valid?
    end

    test "with invalid params returns invalid changeset", ctx do
      changeset = User.changeset(%User{}, ctx.invalid_params)

      refute changeset.valid?
      assert %{name: ["can't be blank"], email: ["has invalid format"]} = errors_on(changeset)
    end

    test "inactivation_date field is optional", ctx do
      changeset = User.changeset(%User{}, ctx.valid_params)

      assert get_field(changeset, :inactivation_date) == nil

      now = DateTime.utc_now()
      params = Map.put(ctx.valid_params, :inactivation_date, now)
      changeset = User.changeset(%User{}, params)

      assert get_field(changeset, :inactivation_date) == DateTime.truncate(now, :second)
    end

    test "email must not have spaces" do
      for email <- ["some@ email", "some @email"] do
        params = params_for(:user, email: email)
        changeset = User.changeset(%User{}, params)

        assert %{email: ["has invalid format"]} = errors_on(changeset)
      end
    end

    test "error on duplicated email" do
      user = insert(:user)
      params = params_for(:user, email: user.email)

      assert {:error, changeset} =
               %User{}
               |> User.changeset(params)
               |> Repo.insert()

      assert errors_on(changeset) == %{email: ["has already been taken"]}
    end

    test "can be used to update user" do
      changeset = insert(:user) |> User.changeset(%{name: "a new name"})

      assert changeset.changes == %{name: "a new name"}
      assert changeset.valid?
    end
  end
end
