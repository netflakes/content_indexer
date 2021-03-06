defmodule ContentIndexer.TfIdf.Corpus.Impl do
  @moduledoc """
    ** Summary **
    functions used by the `ContentIndexer.TfIdf.Corpus.Server`
  """

  @storage_adapter Application.get_env(:content_indexer, :storage_adapter)
  @dets_table_name Application.get_env(:content_indexer, :corpus_dets_table_name)

  def init do
    {:ok, init_state, _state} = @storage_adapter.init(@dets_table_name, %{})
    {:ok, _corpus_size, _state} = case init_state do
      %{} ->
        @storage_adapter.put(:corpus_size, 0, @dets_table_name, %{})
      corpus_state ->
        @storage_adapter.get(:corpus_size, @dets_table_name, corpus_state)
    end
  end

  @doc """
    Increments the corpus document count

    ## Example

      iex> ContentIndexer.TfIdf.Corpus.Impl.increment(2)
            2
  """
  def increment(current_corpus_size) do
    new_corpus_size = current_corpus_size + 1
    {:ok, state, _} = @storage_adapter.state(@dets_table_name, %{})
    @storage_adapter.put(:corpus_size, new_corpus_size, @dets_table_name, state)
  end

  @doc """
    Decrements the corpus document count

    ## Example

      iex> ContentIndexer.TfIdf.Corpus.Impl.decrement(2)
            1
  """
  def decrement(current_corpus_size) do
    new_corpus_size = current_corpus_size - 1
    {:ok, state, _} = @storage_adapter.state(@dets_table_name, %{})
    @storage_adapter.put(:corpus_size, new_corpus_size, @dets_table_name, state)
  end

  @doc """
    Resets the corpus document count

    ## Example

      iex> ContentIndexer.TfIdf.Corpus.Impl.reset
            0
  """
  def reset do
    {:ok, :reset, state} = @storage_adapter.reset(@dets_table_name, 0)
    state
  end
end
