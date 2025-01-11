defmodule Octos.Repo.Migrations.AddNameToCamerasTable do
  use Ecto.Migration

  def change do
    alter table(:cameras) do
      add :name, :string, null: false
    end
  end
end
