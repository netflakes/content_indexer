defmodule ContentIndexer.Services.Index do
  alias Ecto.UUID
  alias ContentIndexer.Services.Index

  defstruct uuid: "", file_name: "", tokens: [], term_weights: %{}

  def new(file_name, tokens) when is_list(tokens) do
    new_uuid = UUID.generate()
    %Index{file_name: file_name, tokens: tokens, uuid: new_uuid}
  end

end