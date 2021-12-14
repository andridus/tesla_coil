defmodule TeslaCoil.Repo do
  @moduledoc """
  A helper to mock external application database in process dictionary
  """

  alias Ecto.Changeset

  @dictionary_key :tesla_coil_repo

  def create_table(schema) do
    if Process.get(:tesla_coil_repo)[schema],
      do: raise("Mocked table #{inspect(schema)} already exists"),
      else: upsert_table(schema, [])
  end

  def insert(%{valid?: true} = changeset) do
    schema = changeset |> changeset_schema()
    data = changeset |> Changeset.apply_changes() |> put_id()
    updated_table = list(schema) ++ [data]

    upsert_table(schema, updated_table)

    {:ok, data}
  end

  def insert(changeset), do: {:error, changeset}

  defp put_id(data), do: data |> Map.put(:id, Ecto.UUID.generate())

  def get(schema, id) do
    list(schema)
    |> Enum.find(&(&1.id == id))
    |> case do
      nil -> {:error, :not_found}
      entry -> {:ok, entry}
    end
  end

  def get!(schema, id) do
    get(schema, id)
    |> case do
      {:ok, entry} -> entry
      {:error, :not_found} -> raise "Mocked #{inspect(schema)} entry with id #{id} don't exists"
    end
  end

  def list(schema),
    do: repo_data()[schema] || raise("Mocked table #{inspect(schema)} don't exists")

  def update(%{valid?: true} = changeset) do
    schema = changeset |> changeset_schema()
    data = changeset |> Changeset.apply_changes()
    table = list(schema)

    updated_table =
      table
      |> Enum.find_index(&(&1.id == data.id))
      |> case do
        nil -> raise "Mocked #{inspect(schema)} entry with id #{data.id} don't exists"
        index -> table |> List.replace_at(index, data)
      end

    upsert_table(schema, updated_table)

    {:ok, data}
  end

  def update(changeset), do: {:error, changeset}

  def delete(%schema{} = data) do
    table = schema |> list()

    updated_table =
      table
      |> Enum.find_index(&(&1.id == data.id))
      |> case do
        nil -> raise "Mocked #{inspect(schema)} entry with id #{data.id} don't exists"
        index -> table |> List.delete_at(index)
      end

    upsert_table(schema, updated_table)

    {:ok, data}
  end

  defp upsert_table(schema, state) do
    repo_data()
    |> Map.put(schema, state)
    |> then(&Process.put(@dictionary_key, &1))

    :ok
  end

  defp repo_data, do: Process.get(@dictionary_key, %{})

  defp changeset_schema(%{data: %schema{}}), do: schema
end
