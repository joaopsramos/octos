defmodule Octos.Factory do
  use ExMachina.Ecto, repo: Octos.Repo

  alias Octos.Accounts.User

  def user_factory do
    %User{
      name: Faker.Person.name(),
      email: Faker.Internet.email()
    }
  end
end
