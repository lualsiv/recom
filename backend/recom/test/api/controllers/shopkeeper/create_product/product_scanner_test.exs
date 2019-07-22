defmodule Recom.Api.Shopkeeper.CreateProduct.ProductScanner do
  use Timex
  use Exceptional

  alias Recom.Entities.Product

  defmodule ScanningError do
    defexception ~w{message reason}a
  end

  def scan(nil) do
    %ScanningError{message: "Nil payload."}
  end

  def scan(payload) do
    payload
    |> check_name()
    ~> check_price()
    ~> check_quantity()
    ~> to_product()
  end

  defp check_name(payload) do
    case payload do
      %{"name" => name} when is_binary(name) ->
        payload

      %{"name" => _} ->
        %ScanningError{
          message: "Invalid payload.",
          reason: %{name: "Invalid type, expected a string."}
        }

      _ ->
        %ScanningError{message: "Invalid payload.", reason: %{name: "Missing."}}
    end
  end

  defp check_price(payload) do
    case payload do
      %{"price" => price} when is_integer(price) ->
        payload

      %{"price" => _} ->
        %ScanningError{
          message: "Invalid payload.",
          reason: %{price: "Invalid type, expected an integer."}
        }

      _ ->
        %ScanningError{message: "Invalid payload.", reason: %{price: "Missing."}}
    end
  end

  defp check_quantity(payload) do
    case payload do
      %{"quantity" => quantity} when is_integer(quantity) ->
        payload

      %{"quantity" => _} ->
        %ScanningError{
          message: "Invalid payload.",
          reason: %{quantity: "Invalid type, expected an integer."}
        }
    end
  end

  defp to_product(payload) do
    %Product{
      name: payload["name"],
      price: payload["price"],
      quantity: payload["quantity"],
      time_span:
        Interval.new(
          from: Timex.parse!(payload["from"], "{ISO:Extended:Z}"),
          until: [days: 8]
        )
    }
  end
end

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
    "end" => "2019-01-09T14:00:00.000000Z"
  }

  @valid_product %Product{
    name: "Orange Juice 2L",
    price: 589,
    quantity: 1_000,
    time_span:
      Interval.new(
        from: ~U[2019-01-01 14:00:00.000000Z],
        until: [days: 8]
      )
  }

  setup context do
    payload =
      if context[:overrides] do
        Enum.reduce(context[:overrides], @valid_payload, fn
          {:delete, field}, payload -> Map.delete(payload, field)
          {:zero, field}, payload -> Map.put(payload, field, 0)
          {:not_an_integer, field}, payload -> Map.put(payload, field, "not an integer")
          _, _ -> raise "Unsupported override instruction."
        end)
      else
        @valid_payload
      end

    [result: ProductScanner.scan(payload)]
  end

  test "payload is nil" do
    assert %ScanningError{message: "Nil payload.", reason: nil} == ProductScanner.scan(nil)
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
end
