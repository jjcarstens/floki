defmodule Floki.HTMLNode do
  defstruct type: "", attributes: [], children_ids: [], floki_parent_id: "", floki_id: ""

  def as_tuple(_tree, %Floki.TextNode{content: text}) do
    text
  end
  def as_tuple(tree, html_node) do
    children = html_node.children_ids
               |> Enum.reverse
               |> Enum.map(fn(id) -> as_tuple(tree, Map.get(tree.tree, id)) end)

    {html_node.type, html_node.attributes, children}
  end
end
