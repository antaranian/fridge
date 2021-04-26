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
end
