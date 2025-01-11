defmodule Octos.Cameras.Workers.NotifyUsersTest do
  use Octos.DataCase, async: true
  use Mimic

  import Swoosh.TestAssertions

  alias Octos.Cameras.Camera
  alias Octos.Cameras.NotifyUserEmail
  alias Octos.Cameras.Workers.NotifyUsers

  setup :verify_on_exit!

  setup do
    %{args: %{brand: Camera.giga()}}
  end

  test "send emails for users who have cameras with given brand", ctx do
    users = insert_list(2, :user, cameras: [build(:camera, brand: Camera.giga())])
    another_user = insert(:user, cameras: [build(:camera, brand: Camera.intelbras())])

    perform_job(NotifyUsers, ctx.args)

    for user <- users do
      user
      |> NotifyUserEmail.notify(Camera.giga())
      |> assert_email_sent()
    end

    for brand <- [Camera.giga(), Camera.intelbras()] do
      another_user
      |> NotifyUserEmail.notify(brand)
      |> assert_email_not_sent()
    end
  end

  test "only send emails for users who have active cameras", ctx do
    user1 = insert(:user, cameras: [build(:camera, brand: Camera.giga(), active: true)])
    user2 = insert(:user, cameras: [build(:camera, brand: Camera.giga(), active: false)])

    perform_job(NotifyUsers, ctx.args)

    user1
    |> NotifyUserEmail.notify(Camera.giga())
    |> assert_email_sent()

    user2
    |> NotifyUserEmail.notify(Camera.giga())
    |> assert_email_not_sent()
  end

  test "only send emails for active users", ctx do
    user1 = insert(:user, inactivation_date: nil, cameras: [build(:camera, brand: Camera.giga())])

    user2 =
      insert(:user,
        inactivation_date: DateTime.utc_now(),
        cameras: [build(:camera, brand: Camera.giga())]
      )

    perform_job(NotifyUsers, ctx.args)

    user1
    |> NotifyUserEmail.notify(Camera.giga())
    |> assert_email_sent()

    user2
    |> NotifyUserEmail.notify(Camera.giga())
    |> assert_email_not_sent()
  end

  test "create another job for each batch", ctx do
    users =
      insert_list(501, :user, cameras: [build(:camera, brand: Camera.giga())])
      |> Enum.sort_by(& &1.id)

    last_batch_user = Enum.at(users, -2)

    perform_job(NotifyUsers, ctx.args)

    assert_enqueued(
      worker: NotifyUsers,
      args: %{brand: Camera.giga(), after_id: last_batch_user.id}
    )

    Oban.drain_queue(queue: :mailer)

    assert all_enqueued(worker: NotifyUsers) == []

    users
    |> List.last()
    |> NotifyUserEmail.notify(Camera.giga())
    |> assert_email_sent()
  end

  test "on email deliver error, update current job with last successful user id", ctx do
    users =
      insert_list(5, :user, cameras: [build(:camera, brand: Camera.giga())])
      |> Enum.sort_by(& &1.id)

    middle_user = Enum.at(users, 2)

    expect(Octos.Mailer, :deliver, 3, fn email ->
      [{_, user_email}] = email.to

      if middle_user.email == user_email do
        {:error, "some error"}
      else
        call_original(Octos.Mailer, :deliver, [email])
      end
    end)

    # Must insert manually the job, because `perform_job/2` does not create it on
    # the database, so the update would cause an `Ecto.StaleEntryError`
    job = ctx.args |> NotifyUsers.new() |> Repo.insert!()

    Oban.drain_queue(queue: :mailer)
    # Moves the job to available because of `assert_enqueued`
    Oban.retry_job(job.id)

    user_before_middle_user = Enum.at(users, 1)

    assert_enqueued(
      worker: NotifyUsers,
      args: %{brand: Camera.giga(), after_id: user_before_middle_user.id}
    )

    Oban.drain_queue(queue: :mailer)

    assert all_enqueued(worker: NotifyUsers) == []

    for user <- users do
      user
      |> NotifyUserEmail.notify(Camera.giga())
      |> assert_email_sent()
    end
  end
end
