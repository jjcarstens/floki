defmodule Floki.HTMLTreeTest do
  use ExUnit.Case, assync: true

  alias Floki.{HTMLTree, HTMLNode, TextNode}

  test "parse the tuple tree into html tree" do
    link_attrs = [{"href", "/home"}]
    html_tuple =
      {"html", [],
       [
         {:comment, "start of the stack"},
         {"a", link_attrs,
          [{"b", [], ["click me"]}]},
         {"span", [], []}]}

    assert HTMLTree.parse(html_tuple) == %HTMLTree{
     root_ids: [1],
     ids: [5, 4, 3, 2, 1],
     tree: %{
       1 => %HTMLNode{type: "html",
                           children_ids: [5, 2],
                           floki_id: 1},
       2 => %HTMLNode{type: "a",
                           attributes: link_attrs,
                           floki_parent_id: 1,
                           children_ids: [3],
                           floki_id: 2},
       3 => %HTMLNode{type: "b",
                           floki_parent_id: 2,
                           children_ids: [4],
                           floki_id: 3},
       4 => %TextNode{content: "click me",
                           floki_parent_id: 3,
                           floki_id: 4},
       5 => %HTMLNode{type: "span",
                           floki_parent_id: 1,
                           floki_id: 5}
     }
    }
  end

  test "parse HTML tuple list" do
    link_attrs = [{"href", "/home"}]
    html_tuple_list = [
      {"html", [],
       [
         {:comment, "start of the stack"},
         {"a", link_attrs,
          [{"b", [], ["click me"]}]},
         {"span", [], []}]}
    ]

    assert HTMLTree.parse(html_tuple_list) == %HTMLTree{
     root_ids: [1],
     ids: [5, 4, 3, 2, 1],
     tree: %{
       1 => %HTMLNode{type: "html",
                           children_ids: [5, 2],
                           floki_id: 1},
       2 => %HTMLNode{type: "a",
                           attributes: link_attrs,
                           floki_parent_id: 1,
                           children_ids: [3],
                           floki_id: 2},
       3 => %HTMLNode{type: "b",
                           floki_parent_id: 2,
                           children_ids: [4],
                           floki_id: 3},
       4 => %TextNode{content: "click me",
                           floki_parent_id: 3,
                           floki_id: 4},
       5 => %HTMLNode{type: "span",
                           floki_parent_id: 1,
                           floki_id: 5}
     }
    }
  end
end
