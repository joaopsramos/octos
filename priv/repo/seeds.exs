alias Octos.Accounts.User
alias Octos.Cameras.Camera
alias Octos.Repo

if Mix.env() != :dev do
  exit(:shutdown)
end

previous_log_level = Logger.level()
Logger.configure(level: :info)

parse_opts = [batch_size: :integer]
{opts, _args} = OptionParser.parse!(System.argv(), strict: parse_opts)
batch_size = opts[:batch_size] || 5000

users_count = 1000
cameras_per_user = 50
now = DateTime.truncate(DateTime.utc_now(), :second)
placeholders = %{now: now}

build_user = fn ->
  %{
    name: Faker.Person.name(),
    email: Faker.Internet.email(),
    inactivation_date: Enum.random([nil, now]),
    inserted_at: {:placeholder, :now},
    updated_at: {:placeholder, :now}
  }
end

insert_users = fn users ->
  {_, inserted} =
    Repo.insert_all(User, users,
      returning: true,
      placeholders: placeholders,
      on_conflict: :nothing
    )

  inserted
end

build_camera = fn user ->
  %{
    brand: Enum.random(Camera.brands()),
    active: Enum.random([true, false]),
    user_id: user.id,
    inserted_at: {:placeholder, :now},
    updated_at: {:placeholder, :now}
  }
end

Repo.transaction(fn ->
  IO.puts("Seeding users...")

  users =
    1..users_count
    |> Enum.map(fn _ -> build_user.() end)
    |> Enum.uniq_by(& &1.email)
    |> Enum.chunk_every(batch_size)
    |> Enum.flat_map(insert_users)

  IO.puts("Seeding cameras...")

  for user <- users, _ <- 1..cameras_per_user do
    build_camera.(user)
  end
  |> Enum.chunk_every(batch_size)
  |> Enum.each(&Repo.insert_all(Camera, &1, placeholders: placeholders))
end)

Logger.configure(level: previous_log_level)
