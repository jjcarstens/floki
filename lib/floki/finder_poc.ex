defmodule Floki.FinderPoc do
  alias Floki.{Combinator, Selector, SelectorParser, SelectorTokenizer}
  alias Floki.{IdsSeeder, HTMLTree, HTMLNode, HTMLText}

  def find(html_as_string, _) when is_binary(html_as_string), do: []
  def find([], _), do: []
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

  defp find_selectors(html_tuple_or_list, [selector | _selectors]) do
    {:ok, pid} = IdsSeeder.start_link

    html_tree = HTMLTree.parse(html_tuple_or_list, pid)
    ids = IdsSeeder.ids(pid)
    GenServer.stop(pid)

    ids
    |> get_nodes(html_tree.tree)
    |> Enum.flat_map(fn(html_node) -> get_matches(html_tree.tree, html_node, selector, ids) end)
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

  defp get_matches(_tree, html_node, selector = %Selector{combinator: nil}, _ids) do
    if Selector.match?(html_node, selector) do
      [html_node]
    else
      []
    end
  end

  # This needs to be recursive taking the html_node as the base
  defp get_matches(tree, html_node, selector = %Selector{combinator: combinator}, ids) do
    if Selector.match?(html_node, selector) do
      traverse_with(combinator, tree, [html_node], ids)
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
  defp traverse_with(_, _, [], _), do: []
  defp traverse_with(nil, _, result, _), do: result
  defp traverse_with(%Combinator{match_type: :child, selector: s}, tree, stack, ids) do
    matches =
      Enum.flat_map(stack, fn(html_node) ->
        nodes = html_node.children_ids
                |> Enum.reverse
                |> get_nodes(tree)

        Enum.filter(nodes, fn(html_node) -> Selector.match?(html_node, s) end)
      end)

    # Here we are saying that the next stack is what was found,
    # and the next find should be a combinator withing that findings.
    # Be awere that the other types of combinators.
    traverse_with(s.combinator, tree, matches, ids)
  end

  defp traverse_with(%Combinator{match_type: :sibling, selector: s}, tree, stack, ids) do
    matches =
      Enum.flat_map(stack, fn(html_node) ->
        sibling_id = get_siblings(html_node, tree)
                     |> Enum.slice(1, 1)

        # It treats sibling as list to easily ignores those that didn't match
        nodes = get_nodes(sibling_id, tree)

        # Finally, try to match those siblings with the selector
        Enum.filter(nodes, fn(html_node) -> Selector.match?(html_node, s) end)
      end)

    traverse_with(s.combinator, tree, matches, ids)
  end

  defp traverse_with(%Combinator{match_type: :general_sibling, selector: s}, tree, stack, ids) do
    matches =
      Enum.flat_map(stack, fn(html_node) ->
        sibling_ids = get_siblings(html_node, tree)

        nodes = get_nodes(sibling_ids, tree)

        # Finally, try to match those siblings with the selector
        Enum.filter(nodes, fn(html_node) -> Selector.match?(html_node, s) end)
      end)

    traverse_with(s.combinator, tree, matches, ids)
  end

  defp traverse_with(%Combinator{match_type: :descendant, selector: s}, tree, stack, ids) do
    matches =
      Enum.flat_map(stack, fn(html_node) ->
        sibling_ids = get_siblings(html_node, tree)
        ids_to_match = get_ids_for_decendant_match(html_node.floki_id, sibling_ids, ids)
        nodes = ids_to_match
                |> get_nodes(tree)

        Enum.filter(nodes, fn(html_node) -> Selector.match?(html_node, s) end)
      end)

    # Here we are saying that the next stack is what was found,
    # and the next find should be a combinator withing that findings.
    # Be awere that the other types of combinators.
    traverse_with(s.combinator, tree, matches, ids)
  end

  defp get_nodes(ids, tree) do
    Enum.map(ids, fn(id) -> Map.get(tree, id) end)
  end

  defp get_node(id, tree) do
    Map.get(tree, id)
  end

  defp get_siblings(html_node, tree) do
    parent = get_node(html_node.floki_parent_id, tree)
    [_html_node_id | sibling_ids] = parent.children_ids
                                    |> Enum.reverse
                                    |> Enum.drop_while(fn(id) -> id != html_node.floki_id end)
    sibling_ids
  end

  # It takes all ids until the next sibling, that represents the ids under a given sub-tree
  defp get_ids_for_decendant_match(floki_id, sibling_ids, ids) do
    [floki_id|ids_after] = Enum.drop_while(ids, fn(id) -> id != floki_id end)

    case sibling_ids do
      [] -> ids_after
      [sibling_id|_] -> Enum.take_while(ids_after, fn(id) -> id != sibling_id end)
    end
  end
end
