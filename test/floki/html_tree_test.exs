defmodule Floki.HTMLTreeTest do
  use ExUnit.Case, assync: true

  alias Floki.{HTMLTree, HTMLNode, TextNode}

  defmodule FakeIdsSeeder do
    use GenServer

    @ids ~w(n-01 n-02 n-03 n-04 n-05)

    def start_link(_opts \\ []) do
      GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    def seed do
      GenServer.call(__MODULE__, :seed)
    end

    ## GenServer API
    def handle_call(:seed, _from, state) do
      ids_length = length(state)
      new_id = Enum.at(@ids, ids_length, "out_of_range")

      {:reply, new_id, [new_id|state]}
    end
  end

  test "parse the tuple tree into html tree" do
    FakeIdsSeeder.start_link
    link_attrs = [{"href", "/home"}]
    html_tuple =
      {"html", [],
       [
         {:comment, "start of the stack"},
         {"a", link_attrs,
          [{"b", [], ["click me"]}]},
         {"span", [], []}]}

    assert HTMLTree.parse(html_tuple, FakeIdsSeeder) == %HTMLTree{
     root_id: "n-01",
     tree: %{
       "n-01" => %HTMLNode{type: "html",
                           children_ids: ["n-05", "n-02"],
                           floki_id: "n-01"},
       "n-02" => %HTMLNode{type: "a",
                           attributes: link_attrs,
                           floki_parent_id: "n-01",
                           children_ids: ["n-03"],
                           floki_id: "n-02"},
       "n-03" => %HTMLNode{type: "b",
                           floki_parent_id: "n-02",
                           children_ids: ["n-04"],
                           floki_id: "n-03"},
       "n-04" => %TextNode{content: "click me",
                           floki_parent_id: "n-03",
                           floki_id: "n-04"},
       "n-05" => %HTMLNode{type: "span",
                           floki_parent_id: "n-01",
                           floki_id: "n-05"}
     }
    }
  end
end
