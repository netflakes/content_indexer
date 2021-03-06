defmodule ContentIndexer.Store.DetsAdapter do
  @moduledoc """
    Erlang DETS storeage adapter used by the Genservers:
    Corpus, DocCounts, DocTerms, TermCounts & WeightsIndexer
  """
  alias ContentIndexer.Store.Utils

  @doc """
    initialise the DETS table as a set with unique keys
  """
  def init(table_name, state) do
    case :dets.open_file(table_name, [type: :set]) do
      {:ok, _dets_table} ->
        all(table_name, state)
      _ ->
        {:error, "failed to open Dets table: #{table_name}"}
    end
  end

  def reset(table_name, _state) do
    :dets.delete_all_objects(table_name)
    {:ok, :reset, %{}}
  end

  def state(table_name, state) do
    all(table_name, state)
  end

  @doc """
    by using a tuple of dets_table_name & the key as a composite key
    it allows us later to match easier to retrieve all the records with this
    composite key
  """
  def put(key, value, table_name, state) do
    case :dets.insert(table_name, {{table_name, key}, value}) do
      :ok ->
        updated_state = Utils.update_state(key, value, state)
        {:ok, value, updated_state}
      _ ->
        {:error, "insert failed!", state}
    end
  end

  def get(key, table_name, state) do
    case :dets.lookup(table_name, {table_name, key}) do
      [{{^table_name, ^key}, value}] -> {:ok, value, state}
      [] -> {:error, "#{key} not found!", state}
    end
  end

  def all(table_name, _state) do
    dets_data = :dets.match_object(table_name, {{table_name, :_}, :_})
    updated_state = dets_data
    |> Utils.dets_all_to_map()
    {:ok, updated_state, updated_state}
  end
end
