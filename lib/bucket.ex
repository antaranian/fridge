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
    processor = fn state ->
      Map.get_and_update(state, item, fn
        nil -> {:err, 0}
        count when count >= amount -> {:ok, count - amount}
        count when count < amount -> {:err, count}
      end)
    end

    Agent.get_and_update(bucket, processor)
  end

  def put_all(bucket, receipt) do
    processor = fn state ->
      Map.merge(state, receipt, fn _k, v1, v2 -> v1 + v2 end)
    end

    Agent.update(bucket, processor)
  end

  def get_all(bucket, receipt) do
    processor = fn state ->
      leftover = Map.merge(state, receipt, fn _k, v1, v2 -> v1 - v2 end)

      case Map.values(leftover) |> Enum.all?(fn x -> x >= 0 end) do
        true -> {:ok, leftover}
        false -> {:err, state}
      end
    end

    Agent.get_and_update(bucket, processor)
  end
end
