defmodule Orange.Runtime.ChildrenDiff do
  @moduledoc """
  Calculate the diff between two lists of children
  The algorithm is as follows:
  1. Find the Longest Common Subsequence (LCS) between the two lists
  2. Iterate the current list, child present in the LCS is considered as old child, otherwise it's new

  To simplify the algorithm, we consider that stateless elements (like Span, Line) are always new.
  This means the children will be rerendered from scratch every time
  """

  alias Orange.{Span, Line, Rect, CustomComponent}

  @type child :: Span.t() | Line.t() | Rect.t() | CustomComponent.t()
  @spec run([child], [child]) :: [
          {:keep, current :: child, prev :: child} | {:new, child} | {:remove, child}
        ]
  def run(current, previous) do
    lcs = lcs(current, previous)

    new_tree =
      current
      |> Enum.with_index()
      |> Enum.map(fn {element, index} ->
        in_lcs = Enum.find(lcs, fn {i, _} -> i == index end)

        case in_lcs do
          {_, j} ->
            case element do
              element
              when is_struct(element, CustomComponent)
              when is_struct(element, Rect) ->
                {:keep, element, Enum.at(previous, j)}

              _ ->
                {:new, element}
            end

          nil ->
            {:new, element}
        end
      end)

    old_tree =
      previous
      |> Enum.with_index()
      |> Enum.map(fn {element, index} ->
        in_lcs = Enum.find(lcs, fn {_, i} -> i == index end)
        if !in_lcs, do: {:remove, element}
      end)
      |> Enum.reject(&is_nil/1)

    new_tree ++ old_tree
  end

  defp lcs(current, previous) do
    {_, memo} = lcs(current, previous, 0, 0, %{max: []})
    Map.get(memo, :max)
  end

  # Returns the LCS for current[0..i-1] and previous[0..j-1]
  defp lcs(current, previous, i, j, memo) do
    update_memo = fn memo, {i, j}, value ->
      memo = Map.put(memo, {i, j}, value)

      max = Map.get(memo, :max)
      if length(value) >= length(max), do: Map.put(memo, :max, value), else: memo
    end

    cond do
      i == length(current) || j == length(previous) ->
        {[], memo}

      same_type(Enum.at(current, i), Enum.at(previous, j)) ->
        {result, memo} = lcs(current, previous, i + 1, j + 1, memo)
        result = result ++ [{i, j}]
        memo = update_memo.(memo, {i, j}, result)
        {result, memo}

      (cached = Map.get(memo, {i, j})) != nil ->
        {cached, memo}

      true ->
        {result1, memo} = lcs(current, previous, i, j + 1, memo)
        {result2, memo} = lcs(current, previous, i + 1, j, memo)
        result = if length(result1) >= length(result2), do: result1, else: result2

        memo = update_memo.(memo, {i, j}, result)
        {result, memo}
    end
  end

  defp same_type(element1, element2) do
    cond do
      is_struct(element1, CustomComponent) and is_struct(element2, CustomComponent) ->
        element1.module == element2.module

      not is_struct(element1, CustomComponent) and not is_struct(element2, CustomComponent) ->
        element1.__struct__ == element2.__struct__

      true ->
        false
    end
  end
end
