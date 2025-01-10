defmodule Octos.Accounts.User do
  @moduledoc """
  User schema
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Octos.Cameras.Camera
  alias __MODULE__

  @derive {Flop.Schema, filterable: [], sortable: []}

  @type t() :: %User{
          name: String.t(),
          email: String.t(),
          inactivation_date: DateTime.t(),
          cameras: list(Camera.t()) | Ecto.Association.NotLoaded.t()
        }

  schema "users" do
    field :name, :string
    field :email, :string, redact: true
    field :inactivation_date, :utc_datetime

    has_many :cameras, Camera

    timestamps(type: :utc_datetime)
  end

  @spec changeset(User.t(), %{required(binary()) => term()} | %{required(atom()) => term()}) ::
          Changeset.t()
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :email, :inactivation_date])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> unique_constraint(:email)
  end
end
