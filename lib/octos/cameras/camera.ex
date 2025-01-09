defmodule Octos.Cameras.Camera do
  @moduledoc """
  Camera schema
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Octos.Accounts.User
  alias __MODULE__

  @brands ["Intelbras", "Hikvision", "Giga", "Vivotek"]

  @type t() :: %Camera{
          brand: String.t(),
          active: boolean(),
          user_id: integer(),
          user: User.t() | Ecto.Association.NotLoaded.t()
        }

  schema "cameras" do
    field :brand, :string
    field :active, :boolean, default: true

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @spec changeset(Camera.t(), %{required(binary()) => term()} | %{required(atom()) => term()}) ::
          Changeset.t()
  def changeset(%Camera{} = camera, attrs) do
    camera
    |> cast(attrs, [:brand, :active, :user_id])
    |> validate_required([:brand, :active, :user_id])
    |> validate_inclusion(:brand, @brands)
  end

  @doc """
  Returns all the available brands.
  """
  @spec brands() :: list(String.t())
  def brands, do: @brands

  # Dynamically generate functions for each brand
  for brand <- @brands do
    func_name = brand |> String.downcase() |> String.to_atom()

    @doc """
    Returns the `"#{brand}"` brand.
    """
    @spec unquote(func_name)() :: String.t()
    def unquote(func_name)(), do: unquote(brand)
  end
end
