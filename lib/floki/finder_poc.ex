defmodule Floki.FinderPoc do
  alias Floki.{Selector, SelectorParser, SelectorTokenizer}
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
    |> Enum.map(fn(id) -> Map.get(html_tree.tree, id) end)
    |> Enum.filter(fn(html_node) -> Selector.match?(html_node, selector) end)
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
end
