defmodule Orange.Runtime.ChildrenDiff do
  @moduledoc false

  # Calculate the diff between two lists of children
  # The algorithm is as follows:
  # 1. Find the Longest Common Subsequence (LCS) between the two lists
  # 2. Iterate the current list, child present in the LCS is considered as old child, otherwise it's new
  #
  # To simplify the algorithm, we consider that stateless elements (like text) are always new.
  # This means that these children will be re-rendered from scratch every time

  alias Orange.{Rect, CustomComponent}

  @type child :: Rect.t() | binary() | CustomComponent.t()
  @spec run([child], [child]) :: [
          {:keep, current :: child, prev :: child} | {:new, child} | {:remove, child}
        ]

  # Both current and previous contain only one element. This is a common case that worth optimizing
  def run([current_child], [previous_child]) do
    with true <- same_type?(current_child, previous_child),
         true <- is_struct(current_child, CustomComponent) or is_struct(previous_child, Rect) do
      [{:keep, current_child, previous_child}]
    else
      _ -> [{:new, current_child}, {:remove, previous_child}]
    end
  end

  def run(current, previous) do
    lcs = lcs(current, previous)

    {new_tree, _, _} =
      Enum.reduce(current, {[], lcs, 0}, fn
        # Found the element in the LCS
        element, {result, [{i, j} | rest_lcs], i} ->
          action =
            if is_struct(element, CustomComponent) or is_struct(element, Rect),
              do: {:keep, element, Enum.at(previous, j)},
              else: {:new, element}

          {result ++ [action], rest_lcs, i + 1}

        element, {result, lcs, index} ->
          {result ++ [{:new, element}], lcs, index + 1}
      end)

    {old_tree, _, _} =
      Enum.reduce(previous, {[], lcs, 0}, fn
        # Found the element in the LCS
        _, {result, [{_, i} | rest_lcs], i} ->
          {result, rest_lcs, i + 1}

        element, {result, lcs, index} ->
          {result ++ [{:remove, element}], lcs, index + 1}
      end)

    new_tree ++ old_tree
  end

  defp lcs(current, previous) do
    {_, memo} = lcs(current, previous, 0, 0, %{max: []})
    Map.get(memo, :max)
  end

  # Returns the LCS for current[0..i-1] and previous[0..j-1]
  defp lcs(current, previous, i, j, memo) do
    cond do
      i == length(current) || j == length(previous) ->
        {[], memo}

      same_type?(Enum.at(current, i), Enum.at(previous, j)) ->
        {result, memo} = lcs(current, previous, i + 1, j + 1, memo)
        result = [{i, j} | result]
        memo = update_memo(memo, {i, j}, result)
        {result, memo}

      (cached = Map.get(memo, {i, j})) != nil ->
        {cached, memo}

      true ->
        {result1, memo} = lcs(current, previous, i, j + 1, memo)
        {result2, memo} = lcs(current, previous, i + 1, j, memo)
        result = if length(result1) >= length(result2), do: result1, else: result2

        memo = update_memo(memo, {i, j}, result)
        {result, memo}
    end
  end

  defp update_memo(memo, {i, j}, value) do
    memo = Map.put(memo, {i, j}, value)
    max = Map.get(memo, :max)
    if length(value) >= length(max), do: Map.put(memo, :max, value), else: memo
  end

  defp same_type?(element1, element2) do
    cond do
      is_binary(element1) ->
        is_binary(element2)

      is_binary(element2) ->
        is_binary(element1)

      is_struct(element1, CustomComponent) and is_struct(element2, CustomComponent) ->
        element1.module == element2.module

      not is_struct(element1, CustomComponent) and not is_struct(element2, CustomComponent) ->
        element1.__struct__ == element2.__struct__

      :else ->
        false
    end
  end
end
