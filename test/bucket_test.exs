defmodule Fridge.BucketTest do
  use ExUnit.Case, async: true
  doctest Fridge.Bucket

  setup do
    {:ok, bucket} = Fridge.Bucket.open()
    %{bucket: bucket}
  end

  describe "count" do
    test "yield `0` when not available", %{bucket: bucket} do
      assert Fridge.Bucket.count(bucket, "egg") == 0
    end

    test "yield amound when available", %{bucket: bucket} do
      # setup
      Fridge.Bucket.put(bucket, "milk", 2)

      assert Fridge.Bucket.count(bucket, "milk") == 2
    end
  end

  describe "put" do
    test "create record when not available", %{bucket: bucket} do
      assert Fridge.Bucket.put(bucket, "milk", 2) == :ok
      assert Fridge.Bucket.count(bucket, "milk") == 2
    end

    test "increase total when available amount", %{bucket: bucket} do
      assert Fridge.Bucket.put(bucket, "milk", 2) == :ok
      assert Fridge.Bucket.count(bucket, "milk") == 2

      assert Fridge.Bucket.put(bucket, "milk", 2) == :ok
      assert Fridge.Bucket.count(bucket, "milk") == 4
    end

    test "increase by `1` if `amount` omitted", %{bucket: bucket} do
      assert Fridge.Bucket.put(bucket, "milk") == :ok
      assert Fridge.Bucket.count(bucket, "milk") == 1

      assert Fridge.Bucket.put(bucket, "milk") == :ok
      assert Fridge.Bucket.count(bucket, "milk") == 2
    end
  end

  describe "get" do
    setup %{bucket: bucket} do
      Fridge.Bucket.put(bucket, "milk", 5)

      %{bucket: bucket}
    end

    test "reduce total by `amount` if available", %{bucket: bucket} do
      assert Fridge.Bucket.get(bucket, "milk", 2) == :ok
      assert Fridge.Bucket.count(bucket, "milk") == 3
    end

    test "get `1` if `amount` is omitted", %{bucket: bucket} do
      assert Fridge.Bucket.get(bucket, "milk") == :ok
      assert Fridge.Bucket.count(bucket, "milk") == 4
    end

    test "yield `:err` if amount not available", %{bucket: bucket} do
      assert Fridge.Bucket.get(bucket, "egg", 1) == :err
      assert Fridge.Bucket.count(bucket, "egg") == 0

      assert Fridge.Bucket.get(bucket, "milk", 10) == :err
      assert Fridge.Bucket.count(bucket, "milk") == 5
    end
  end

  describe "put_all" do
    test "should put all items", %{bucket: bucket} do
      receipt = %{"milk" => 2, "egg" => 2}
      assert Fridge.Bucket.put_all(bucket, receipt) == :ok
      assert Fridge.Bucket.count(bucket, "milk") == 2
      assert Fridge.Bucket.count(bucket, "egg") == 2
    end

    test "should put all items again", %{bucket: bucket} do
      receipt = %{"milk" => 2, "egg" => 2}
      assert Fridge.Bucket.put_all(bucket, receipt) == :ok
      assert Fridge.Bucket.put_all(bucket, receipt) == :ok
      assert Fridge.Bucket.count(bucket, "milk") == 4
      assert Fridge.Bucket.count(bucket, "egg") == 4
    end
  end

  describe "get_all" do
    setup %{bucket: bucket} do
      Fridge.Bucket.put(bucket, "milk", 5)
      Fridge.Bucket.put(bucket, "egg", 10)

      %{bucket: bucket}
    end

    test "should take out all items", %{bucket: bucket} do
      receipt = %{"milk" => 2, "egg" => 2}
      assert Fridge.Bucket.get_all(bucket, receipt) == :ok
      assert Fridge.Bucket.count(bucket, "milk") == 3
      assert Fridge.Bucket.count(bucket, "egg") == 8
    end

    test "should take none if not enough", %{bucket: bucket} do
      receipt = %{"milk" => 2, "egg" => 12, "tomato" => 2}
      assert Fridge.Bucket.get_all(bucket, receipt) == :err
      assert Fridge.Bucket.count(bucket, "milk") == 5
      assert Fridge.Bucket.count(bucket, "egg") == 10
    end
  end
end
