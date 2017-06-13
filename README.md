# ScopedRepo

Magical scoped repositories for Ecto

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `scoped_repo` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:scoped_repo, "~> 0.1.0"}]
end
```

## Usage

Define a scoped repo module based on a parent resource you want to scope by. Example:

```elixir
defmodule YourApp.Repos.UserRepo do
  use ScopedRepo, scope_by: YourApp.Schemas.User, repo: YourApp.Repo
end
```

It will go out, look at the associations in your parent schema. Let's say it looks something like this:

```elixir
defmodule YourApp.Schemas.User do
  @moduledoc """
  Schema for a User
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    # .. some fields here

    has_one  :spouse,        YourApp.Schemas.Spouse
    has_many :assets,        YourApp.Schemas.Asset

    timestamps()
  end
end
```

It will then generate a lot of function clauses for you, so you can pull in spouse and asset records by scoping them to the correct user. For example:

```elixir
UserRepo.one(user, :spouse)
# The atom must match the name of the association in the schema, pluralization included
UserRepo.get(user, :assets, 20)  # where 20 is the id of an asset
UserRepo.all(user, :assets)

# Bang methods are defined too
UserRepo.one!(user, :spouse, 20)
UserRepo.get!(user, :assets, 20)

# You can do inserts and updates and deletes.
# For updates and deletes, ids are mandatory even for has_one relationships
UserRepo.insert(user, :assets, %{...})
UserRepo.update(user, :spouse, 20, %{...})
UserRepo.delete(user, :assets, 20)

# And even pass in custom changesets for insert & update
UserRepo.insert(user, :assets, %{...}, changeset: &Asset.insert_changeset/2)
UserRepo.update(user, :assets, 20, %{...}, changeset: &Asset.update_changeset/2)
```
