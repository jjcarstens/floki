defmodule Floki.HTMLTree do
  defstruct tree: %{}, root_ids: [], ids: []

  alias Floki.{HTMLNode, HTMLTree, TextNode, IdsSeeder}

  defmodule Stack do
    defstruct parent_node_id: nil, children: []
  end

  def parse(html_as_list) when is_list(html_as_list) do
    reducer = fn
      ({tag, attrs, children}, tree) ->
        root_id = IdsSeeder.seed(tree.ids)

        root_node = %HTMLNode{type: tag, attributes: attrs, floki_id: root_id}
        nodes_tree = Map.put(tree.tree, root_id, root_node)
        new_tree = %{tree | tree: nodes_tree,
                            ids: [root_id | tree.ids],
                            root_ids: [root_id | tree.root_ids]}

        parse_tree(new_tree, children, root_id, [])
      (_, tree) ->
        tree
    end

    Enum.reduce(html_as_list, %HTMLTree{}, reducer)
  end

  def parse({tag, attrs, children}) do
    root_id = IdsSeeder.seed([])

    root_node = %HTMLNode{type: tag, attributes: attrs, floki_id: root_id}
    tree = %HTMLTree{
      root_ids: [root_id],
      ids: [root_id],
      tree: %{
        root_id => root_node
      }
    }

    parse_tree(tree, children, root_id, [])
  end

  defp parse_tree(tree, [], _, []), do: tree
  defp parse_tree(tree, [text | children], parent_id, stack) when is_binary(text) do
    previous = tree.tree
    new_id = IdsSeeder.seed(tree.ids)
    new_node = %TextNode{content: text,
                         floki_id: new_id,
                         floki_parent_id: parent_id}

    parent_node = Map.get(previous, parent_id)
    children_ids = parent_node.children_ids
    updated_parent = %{parent_node | children_ids: [new_id | children_ids]}

    newer =
      previous
      |> Map.put(new_id, new_node)
      |> Map.put(parent_id, updated_parent)

    parse_tree(%{tree | tree: newer, ids: [new_id | tree.ids]}, children, parent_id, stack)
  end
  defp parse_tree(tree, [{tag, attrs, child_children} | children], parent_id, stack) do
    previous = tree.tree
    new_id = IdsSeeder.seed(tree.ids)
    new_node = %HTMLNode{type: tag,
                         attributes: attrs,
                         floki_id: new_id,
                         floki_parent_id: parent_id}

    parent_node = Map.get(previous, parent_id)
    children_ids = parent_node.children_ids
    updated_parent = %{parent_node | children_ids: [new_id | children_ids]}

    newer =
      previous
      |> Map.put(new_id, new_node)
      |> Map.put(parent_id, updated_parent)

    s = %Stack{parent_node_id: parent_id, children: children}

    parse_tree(%{tree | tree: newer, ids: [new_id | tree.ids]}, child_children, new_id, [s | stack])
  end
  defp parse_tree(tree, [_other | children], parent_id, stack) do
    parse_tree(tree, children, parent_id, stack)
  end
  defp parse_tree(tree, [], _, [stack_h | stack]) do
    parse_tree(tree, stack_h.children, stack_h.parent_node_id, stack)
  end
end
