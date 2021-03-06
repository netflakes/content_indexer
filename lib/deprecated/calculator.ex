defmodule ContentIndexer.Services.Calculator do
  use GenServer

  alias ContentIndexer.Services.{ListCheckerWorker, ListCheckerServer}

  @moduledoc """
    ** Summary **
      calculates the content_indexer weights for a document of tokens against a corpus of tokenized documents

      DEPRECATED - use the `ContentIndexer.TfIdf.Calculate` module.

      See also `ContentIndexer.TfIdf.IndexProcessTest`

  """

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def init(:ok) do
    {:ok, init_calculator()}
  end

  def init_calculator do
    IO.puts "\nInitialising Calculator\n"
  end

  def total(count) do
    GenServer.call(__MODULE__, {:total, count})
  end

  @doc """
    calculates the word count for each token in the list of tokens representing the document
    and returns a list of the tokens with their respective word counts

    ## Parameters

      - tokens: List of tokens to be indexed

    ## Example

      iex> ContentIndexerService.calculate_token_count_document(["bread","butter","jam","jam","bread","bread"])
            {:ok, [bread: 3, butter: 1, jam: 2]}
  """
  def calculate_token_count_document(tokens) do
    token_stream = Stream.map(tokens, fn(token) ->
      {token, word_count(token, tokens)}
    end)
    uniq_tokens = token_stream |> Stream.uniq |> Enum.to_list
    {:ok, uniq_tokens}
  end

  @doc """
    calculates the term frequency for each token in the list of tokens representing the document
    and returns a list of the tokens with their respective term frequencies

    ## Parameters

      - tokens: List of tokens to be indexed

    ## Example

      iex> ContentIndexerService.calculate_tf_document(["bread","butter","jam","jam","bread","bread"])
            {:ok, [bread: 0.5, butter: 0.16666666666666666, jam: 0.3333333333333333]}
  """
  def calculate_tf_document(tokens) do
    token_stream = Stream.map(tokens, fn(token) ->
      {token, tf(token, tokens)}
    end)
    uniq_tokens = token_stream |> Stream.uniq |> Enum.to_list
    {:ok, uniq_tokens}
  end

  @doc """
    calculates the content_indexer weights for each token in the query - weights the query against itself

    ## Parameters

      - tokens: List of tokens to be indexed

    ## Example

      iex> ContentIndexerService.calculate_content_indexer_query(["bread","butter","jam"])
            {:ok, [bread: 0.0, butter: 0.0, jam: 0.0]}
  """
  def calculate_content_indexer_query(tokens) do
    tokenized_tokens = case tokens do
      [_|_] ->
        tokens
      _ ->
        tokenize(tokens)
    end
    token_content_indexer_counts = tokenized_tokens
    |> Enum.uniq
    |> Enum.map(fn(token) ->
      {token, (tf(token, tokenized_tokens) * idf_streamed(token, 1, [tokens]))}
    end)
    {:ok, token_content_indexer_counts}
  end

  @doc """
    calculates the content_indexer weights for each token in the list of tokens against the corpus of tokens

    ## Parameters

      - tokens: List of tokens to be indexed
      - corpus_of_tokens: List of lists representing the corpus of all tokens

    ## Example

      iex> ContentIndexerService.calculate_content_indexer_documents(
              ["bread","butter","jam"],
              [
                ["red","brown","jam"],
                ["blue","green","butter"],
                ["pink","green","bread","jam"]
              ])
            {:ok, [bread: 0.3662040962227032, butter: 0.3662040962227032,jam: 0.3662040962227032]}
  """
  def calculate_content_indexer_documents(tokens, corpus_of_tokens) do
    corpus_size = length(corpus_of_tokens) # this is so we can avoid calculating it again!
    case corpus_size do
      1 ->
        calculate_content_indexer_documents_single(tokens, corpus_of_tokens)
      _ ->
        calculate_content_indexer_documents_multiple(tokens, corpus_of_tokens, corpus_size)
    end
  end

  @doc """
    calculates the content_indexer weights for each token in the list of tokens against the corpus of tokens

    ## Parameters

      - tokens: List of tokens to be indexed
      - corpus_of_tokens: List of lists representing the corpus of all tokens
      - corpus_size: Integer with the size of the corpus_of_tokens - just so we can avoid re-calculating it

    ## Example

      iex> ContentIndexerService.calculate_content_indexer_documents(
            ["bread","butter","jam"],
            [
              ["red","brown","jam"],
              ["blue","green","butter"],
              ["pink","green","bread","jam"]
            ])
            {:ok, [bread: 0.3662040962227032, butter: 0.3662040962227032,jam: 0.3662040962227032]}
  """
  def calculate_content_indexer_documents(tokens, corpus_of_tokens, corpus_size) do
    case corpus_size do
      1 ->
        calculate_content_indexer_documents_single(tokens, corpus_of_tokens)
      _ ->
        calculate_content_indexer_documents_multiple(tokens, corpus_of_tokens, corpus_size)
    end
  end

  @doc """
    simple function to check if an item is contained in the list

    ## Parameters

      - list: List of any type
      - item: Any type of item stored in the list

    ## Example

      iex> ContentIndexerService.calculate_content_indexer_documents(
            ["bread","butter","jam"],
            [
              ["red","brown","jam"],
              ["blue","green","butter"],
              ["pink","green","bread","jam"]
            ])
            {:ok, [bread: 0.3662040962227032, butter: 0.3662040962227032,jam: 0.3662040962227032]}
  """
  def list_contains(list, item), do: Enum.find(list, &(item == &1)) != nil

  # - internal genserver call handler methods

  def handle_call({:state}, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_call({:total, _count}, _from, state) do
    {:reply, {:ok, state}, state}
  end

  # - private methods

  defp calculate_content_indexer_documents_single(tokens, corpus_of_tokens) do
    token_content_indexer_counts = tokens
    |> Enum.uniq
    |> Enum.map(fn(token) ->
      {token, (tf(token, tokens) * idf(token, corpus_of_tokens))}
    end)

    {:ok, token_content_indexer_counts}
  end

  # The corpus_of_tokens has more than one document in it
  defp calculate_content_indexer_documents_multiple(tokens, corpus_of_tokens, corpus_size) do
    token_content_indexer_counts = tokens
    |> Enum.uniq
    |> Enum.map(fn(token) ->
      {to_string(token), (tf(token, tokens) * idf_streamed(token, corpus_size, corpus_of_tokens))}
    end)
    {:ok, token_content_indexer_counts}
  end

  defp idf_streamed(word, corpus_size, corpus_of_tokens) do
    :math.log(corpus_size / (1 + n_containing_calc(word, corpus_of_tokens, corpus_size)))
  end

  # Corpus of tokens is a list of tuples with the index being the second item in the tuple
  defp n_containing_calc(word, corpus_of_tokens, collection_size) do
    ListCheckerServer.initialise_collection(collection_size, self())
    indexed_stream = Stream.with_index(corpus_of_tokens)
    indexed_stream |> Enum.each(fn(streamed_item) ->
      {tokens, index} = streamed_item
      ListCheckerWorker.list(index, word, tokens)
    end)

    total = receive do
      {:total, count} ->
        count
    end
    total
  end

  defp idf(word, corpus_of_tokens) do
    :math.log(length(corpus_of_tokens) / (1 + n_containing(word, corpus_of_tokens)))
  end

  defp tf(word, tokens) do
    word_count(word, tokens) / length(tokens)
  end

  defp word_count(word, tokens) do
    Enum.reduce(tokens, 0, fn(cur_word, acc) ->
      if cur_word == word, do: acc + 1, else: acc
    end)
  end

  defp n_containing(word, corpus_of_tokens) do
    Enum.reduce(corpus_of_tokens, 0, fn(text, acc) ->
      if list_contains(text, word), do: acc + 1, else: acc
    end)
  end

  defp tokenize(text, split_char \\ ",") do
    split_str = String.split(text, split_char)
    split_str |> Enum.filter(fn x -> x != "" end) # remove empty elements
  end
end
