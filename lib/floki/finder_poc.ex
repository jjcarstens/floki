defmodule Floki.FinderPoc do
  alias Floki.{Combinator, Selector, SelectorParser, SelectorTokenizer}
  alias Floki.{IdsSeeder, HTMLTree, HTMLNode, HTMLText}

  def find(html_tree, selector_as_string) when is_binary(selector_as_string) do
    selectors = get_selectors(selector_as_string)
    find_selectors(html_tree, selectors)
  end
  def find(html_tree, selectors) when is_list(selectors) do
    find_selectors(html_tree, selectors)
  end
  def find(html_tree, %Selector{} = selector) do
    find_selectors(html_tree, [selector])
  end

  defp find_selectors(html_tree_as_tuple, [selector | _selectors]) do
    {:ok, pid} = IdsSeeder.start_link

    html_tree = HTMLTree.parse(html_tree_as_tuple, pid)
    ids = IdsSeeder.ids(pid)
    GenServer.stop(pid)

    ids
    |> get_nodes(html_tree.tree)
    |> Enum.flat_map(fn(html_node) -> get_matches(html_tree.tree, html_node, selector) end)
    |> Enum.map(fn(html_node) -> HTMLNode.as_tuple(html_tree, html_node) end)
  end

  defp get_selectors(selector_as_string) do
    selector_as_string
    |> String.split(",")
    |> Enum.map(fn(s) ->
      tokens = SelectorTokenizer.tokenize(s)

      SelectorParser.parse(tokens)
    end)
  end

  defp get_nodes(ids, tree) do
    Enum.map(ids, fn(id) -> Map.get(tree, id) end)
  end

  defp get_matches(_tree, html_node, selector = %Selector{combinator: nil}) do
    if Selector.match?(html_node, selector) do
      [html_node]
    else
      []
    end
  end

  # This needs to be recursive taking the html_node as the base
  defp get_matches(tree, html_node, selector = %Selector{combinator: combinator}) do
    if Selector.match?(html_node, selector) do
      traverse_with(combinator, tree, [html_node])
    else
      []
    end
  end

  # When stack is empty, and we have acc, we should ask if there is any other combinator
  # in combinator.selector.combinator.
  # If so, we should search that too
  # defp traverse_with(combinator, tree, parent_node, stack, acc) do
  #  []
  # end
  defp traverse_with(_, _, []), do: []
  defp traverse_with(nil, _, result), do: result
  defp traverse_with(%Combinator{match_type: :child, selector: s}, tree, stack) do
    matches =
      Enum.flat_map(stack, fn(html_node) ->
        nodes = html_node.children_ids
                |> Enum.reverse
                |> get_nodes(tree)

        Enum.filter(nodes, fn(html_node) -> Selector.match?(html_node, s) end)
      end)

    # Here we are saying that the next stack is what was founded,
    # and the next find should be an combinator withing that findings.
    # Be awere that the other types of combinators.
    traverse_with(s.combinator, tree, matches)
  end
end
