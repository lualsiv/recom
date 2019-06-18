defmodule Storage.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Storage.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Storage.DataCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Storage.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Storage.Repo, {:shared, self()})
    end

    :ok
  end
end
