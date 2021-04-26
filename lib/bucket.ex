defmodule Fridge.Bucket do
  use Agent

  @doc """
  Starts a new bucket.
  """
  def open() do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Counts amount of given `item` in the `bucket`.
  """
  def count(bucket, item) do
    default_amount = 0
    Agent.get(bucket, &Map.get(&1, item, default_amount))
  end

  @doc """
  Puts given amount of `item` in the `bucket`.
  """
  def put(bucket, item, amount \\ 1) do
    top_up = fn count -> count + amount end
    Agent.update(bucket, &Map.update(&1, item, amount, top_up))
  end

  @doc """
  Gets given amount of item from bucket if available
  """
  def get(bucket, item, amount \\ 1) do
    taker = fn state ->
      Map.get_and_update(state, item, fn count ->
        cond do
          count == nil ->
            {:err, 0}

          count >= amount ->
            {:ok, count - amount}

          count < amount ->
            {:err, count}
        end
      end)
    end

    Agent.get_and_update(bucket, taker)
  end

  def put_all(bucket, receipt) do
    processor = fn state ->
      with items <- Map.keys(receipt),
           updated <-
             state
             |> Map.take(items)
             |> Map.merge(receipt, fn _k, v1, v2 -> v1 - v2 end),
           do: Map.merge(state, updated)
    end

    Agent.update(bucket, processor)
  end

  def get_all(bucket, receipt) do
    processor = fn state ->
      leftover =
        with items <- Map.keys(receipt) do
          state
          |> Map.take(items)
          |> Map.merge(receipt, fn _k, v1, v2 -> v1 - v2 end)
        end

      is_valid_leftover? =
        Map.values(leftover)
        |> Enum.map(fn x -> x >= 0 end)
        |> Enum.reduce(true, fn p, acc -> p && acc end)

      case is_valid_leftover? do
        true -> {:ok, leftover}
        false -> {:err, state}
      end
    end

    Agent.get_and_update(bucket, processor)
  end
end
