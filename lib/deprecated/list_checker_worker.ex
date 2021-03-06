defmodule ContentIndexer.Services.ListCheckerWorker do
  @moduledoc """
    genserver based approach to the ListCheckerWorker
    ** Summary **
      ListCheckerWorker is the OTP actor that handles the actual ContentIndexerService.list_contains to check
      whether a given word is contained in a list of tokens

     Due to the fact that we have a very large dataset - potentially millions - a process is spawned for each

   ** Basic Useage **

    A method is called by the server for each list of tokens and returns a result based on whether
    a given word was found in the list or not
  """
  use GenServer

  alias ContentIndexer.Services.Calculator
  alias ContentIndexer.Services.ListCheckerServer

  #-------------------------------------------------------------------#
  # ListCheckerWorker client functions
  #-------------------------------------------------------------------#

  def init_worker do
    IO.puts "\nInitialising ListCheckerWorker\n"
  end

    @doc """
    Checks with a worker whether an item is contained in the list
    The function response just indicates that the process was kicked

    ## Parameters

      - index: Integer representing the index of the list
      - word: String - word to be found
      - tokens: List of tokens to be searched

    ## Example

      iex> ContentIndexer.Services.ListCheckerWorker.list(1, "bread", ["bread", "butter", "jam"])
            {:ok, :ok}
  """
  def list(index, word, tokens) do
    GenServer.call(__MODULE__, {:list, index, word, tokens})
  end

  #-------------------------------------------------------------------#
  # Genserver methods to handle it's message passing
  #-------------------------------------------------------------------#

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def init(:ok) do
    {:ok, init_worker()}
  end

  def handle_call({:list, index, word, tokens}, _from, state) do
    if Calculator.list_contains(tokens, word) do
      ListCheckerServer.count(index, 1)
    else
      ListCheckerServer.count(index, 0)
    end
    {:reply, {:ok, state}, state}
  end
end
