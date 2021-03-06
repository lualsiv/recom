defmodule Recom.Api.Shopkeeper.CreateProduct.ProductScannerTest do
  use ExUnit.Case, async: true
  use Timex

  alias Recom.Entities.Product
  alias Recom.Api.Shopkeeper.CreateProduct.ProductScanner
  alias Recom.Api.Shopkeeper.CreateProduct.ProductScanner.ScanningError

  @valid_payload %{
    "name" => "Orange Juice 2L",
    "price" => 589,
    "quantity" => 1_000,
    "from" => "2019-01-01T14:00:00.000000Z",
    "end" => "2019-01-08T14:00:00.000000Z"
  }

  @valid_product %Product{
    name: "Orange Juice 2L",
    price: 589,
    quantity: 1_000,
    time_span:
      Interval.new(
        from: ~U[2019-01-01 14:00:00.000000Z],
        until: [days: 7]
      )
  }

  setup context do
    payload =
      if context[:overrides] do
        Enum.reduce(context[:overrides], @valid_payload, fn
          {:delete, field}, payload -> Map.delete(payload, field)
          {:zero, field}, payload -> Map.put(payload, field, 0)
          {:not_an_integer, field}, payload -> Map.put(payload, field, "not an integer")
          {:not_a_datetime, field}, payload -> Map.put(payload, field, "not a datetime")
          :swap_dates, payload -> swap_dates(payload)
          _, _ -> raise "Unsupported override instruction."
        end)
      else
        @valid_payload
      end

    [result: ProductScanner.scan(payload)]
  end

  defp swap_dates(payload) do
    from = payload["from"]
    the_end = payload["end"]

    payload
    |> Map.put("from", the_end)
    |> Map.put("end", from)
  end

  test "payload is not a map" do
    assert %ScanningError{message: "Cannot scan this payload.", reason: nil} ==
             ProductScanner.scan(nil)
  end

  test "payload with all fields of valid type" do
    assert Product.equals?(@valid_product, ProductScanner.scan(@valid_payload))
  end

  @tag overrides: [zero: "name"]
  test "name with an invalid type", context do
    assert %ScanningError{
             message: "Invalid payload.",
             reason: %{name: "Invalid type, expected a string."}
           } = context.result
  end

  @tag overrides: [delete: "name"]
  test "name is missing", context do
    assert %ScanningError{
             message: "Invalid payload.",
             reason: %{name: "Missing."}
           } = context.result
  end

  @tag overrides: [not_an_integer: "price"]
  test "price has an invalid type", context do
    assert %ScanningError{
             message: "Invalid payload.",
             reason: %{price: "Invalid type, expected an integer."}
           } = context.result
  end

  @tag overrides: [delete: "price"]
  test "price is missing", context do
    assert %ScanningError{
             message: "Invalid payload.",
             reason: %{price: "Missing."}
           } = context.result
  end

  @tag overrides: [not_an_integer: "quantity"]
  test "quantity is not an integer", context do
    assert %ScanningError{
             message: "Invalid payload.",
             reason: %{quantity: "Invalid type, expected an integer."}
           } = context.result
  end

  @tag overrides: [delete: "quantity"]
  test "quantity is missing", context do
    assert %ScanningError{message: "Invalid payload.", reason: %{quantity: "Missing."}} ==
             context.result
  end

  @tag overrides: [delete: "from"]
  test "from is missing", context do
    assert %ScanningError{message: "Invalid payload.", reason: %{from: "Missing."}} ==
             context.result
  end

  @tag overrides: [not_a_datetime: "from"]
  test "from is not a datetime", context do
    assert %ScanningError{
             message: "Invalid payload.",
             reason: %{from: "Invalid type, expected a datetime."}
           } == context.result
  end

  @tag overrides: [delete: "end"]
  test "end is missing", context do
    assert %ScanningError{message: "Invalid payload.", reason: %{end: "Missing."}} ==
             context.result
  end

  @tag overrides: [not_a_datetime: "end"]
  test "end is not a datetime", context do
    assert %ScanningError{
             message: "Invalid payload.",
             reason: %{end: "Invalid type, expected a datetime."}
           } == context.result
  end

  @tag overrides: [:swap_dates]
  test "end precedes from", context do
    assert %ScanningError{
             message: "Invalid payload.",
             reason: %{end: "The end value should not precede the from value."}
           } == context.result
  end
end
