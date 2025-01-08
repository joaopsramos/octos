defmodule Octos.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :inactivation_date, :utc_datetime, null: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
  end
end
