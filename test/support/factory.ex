defmodule Octos.Factory do
  use ExMachina.Ecto, repo: Octos.Repo

  alias Octos.Accounts.User
  alias Octos.Cameras.Camera

  def user_factory do
    %User{
      name: Faker.Person.name(),
      email: Faker.Internet.email()
    }
  end

  def camera_factory do
    %Camera{
      brand: Enum.random(Camera.brands()),
      name: Faker.Superhero.name(),
      active: true
    }
  end
end
