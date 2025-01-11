defmodule Octos.Cameras.Workers.NotifyUsers do
  @moduledoc """
  An Oban worker that send emails to users with specific camera brand.

  - After processing each batch of users, a new job is created to handle the remaining ones.
  - If an error occurs during the email sending process, the job is updated to resume from
  the last successfully processed user.
  """
  use Oban.Worker, queue: :mailer

  import Ecto.Query

  alias Octos.Accounts.User
  alias Octos.Cameras.NotifyUserEmail
  alias Octos.Repo

  @batch_size 500

  @impl true
  def perform(%Job{args: %{"brand" => brand} = args} = job) do
    after_id = args["after_id"] || 0

    users =
      from(u in User,
        distinct: true,
        join: c in assoc(u, :cameras),
        where: ilike(c.brand, ^brand),
        where: c.active,
        where: is_nil(u.inactivation_date),
        where: u.id > ^after_id,
        order_by: [asc: u.id],
        limit: @batch_size
      )
      |> Repo.all()

    if Enum.empty?(users) do
      :ok
    else
      do_perform(users, brand, after_id, job)
    end
  end

  defp do_perform(users, brand, after_id, job) do
    case send_emails(users, brand, after_id) do
      {:error, reason, last_id} ->
        job
        |> Ecto.Changeset.change(%{args: %{"brand" => brand, "after_id" => last_id}})
        |> Repo.update!()

        {:error, reason}

      last_id when length(users) >= @batch_size ->
        %{"brand" => brand, "after_id" => last_id}
        |> __MODULE__.new()
        |> Oban.insert()

        :ok

      _ ->
        :ok
    end
  end

  defp send_emails(users, brand, after_id) do
    Enum.reduce_while(users, after_id, fn user, previous_id ->
      user
      |> NotifyUserEmail.notify(brand)
      |> Octos.Mailer.deliver()
      |> case do
        {:ok, _} -> {:cont, user.id}
        {:error, reason} -> {:halt, {:error, reason, previous_id}}
      end
    end)
  end
end
