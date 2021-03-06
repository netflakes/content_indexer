
[![Build Status](https://travis-ci.org/netflakes/content_indexer.svg?branch=master)](https://travis-ci.org/netflakes/content_indexer)

# ContentIndexer

ContentIndexer is a small GenServer based indexing & searching service. Intially I created this for my blog that is based on markdown. When the total amount of data to be indexed is not huge this small service can handle it very quickly. It stores the index in a genserver and hence searching is very fast.

It uses tf-idf matching & weighting for the actual index. The searching is done in the same way and comparing the query against the index via similarity.

## What is tf-idf?
> tf–idf, short for term frequency–inverse document frequency, is a numerical statistic that is intended to reflect how important a word is to a document in a collection or corpus. It is often used as a weighting factor in information retrieval and text mining.

[Helpful blog post](http://stevenloria.com/finding-important-words-in-a-document-using-tf-idf/)

[tf-idf background info](https://en.wikipedia.org/wiki/Tf%E2%80%93idf)

## Installation

The library is [available in Hex](https://hex.pm/docs/publish). The package can be installed
by adding `content_indexer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:content_indexer, "~> 0.2.0"}]
end
```

## Usage

Please review this test `ContentIndexer.TfIdf.IndexProcessTest` for the easiest way to know how you can use this in your project.
The module `ContentIndexer.Services.PreProcess` has several functions that are used to pre-process both the content and the queries - since these
are passed as functions you can write your own versions of these and pass them into the content tokenisation and query building process.

Currently I am using this to process markdown files for my blog - but this can be useful for any other such text based content.

The hex documentation is here [https://hexdocs.pm/content_indexer](https://hexdocs.pm/content_indexer).

## Running tests

Clone the repo and fetch its dependencies:

```
$ git clone https://github.com/netflakes/content_indexer.git
$ cd ecto
$ mix deps.get
$ mix test
```

### License

The source code is licensed under the [MIT license](https://opensource.org/licenses/MIT)
