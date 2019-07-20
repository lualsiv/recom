defmodule Recom.Api.Shopkeeper.CreateProductControllerTest do
  use ExUnit.Case, async: true
  use Timex

  import Mox
  import Plug.Test, only: [conn: 3]
  import Plug.Conn, only: [get_resp_header: 2]

  setup :verify_on_exit!

  alias Recom.Api.Shopkeeper.CreateProductController
  alias Recom.Api.Shopkeeper.CreateProduct.Presenter
  alias Recom.Api.Shopkeeper.CreateProduct.PayloadScanner
  alias Recom.Api.Shopkeeper.CreateProduct.PayloadScanner.ScanningError
  alias Recom.Usecases.Shopkeeper.CreateProduct
  alias Recom.Entities.Product

  defmock(PayloadScanner.Stub, for: PayloadScanner)
  defmock(Presenter.Stub, for: Presenter)
  defmock(CreateProduct.Double, for: CreateProduct.Behaviour)

  defp http_request(with_payload: payload), do: conn(:post, "/create_product", payload)

  defp assert_json_response(response) do
    assert ["application/json"] == get_resp_header(response, "content-type")
  end

  describe "invalid json payload" do
    setup do
      stub(PayloadScanner.Stub, :scan, fn _ -> %ScanningError{} end)
      stub(Presenter.Stub, :present, fn _ -> "details about the scanning error" end)

      response =
        http_request(with_payload: "invalid_payload")
        |> CreateProductController.create_product(
          with_scanner: PayloadScanner.Stub,
          with_usecase: nil,
          with_presenter: Presenter.Stub
        )

      [response: response]
    end

    test "it sends a response", context do
      assert context.response.state == :sent
    end

    test "it sets the status to 422", context do
      assert context.response.status == 422
    end

    test "it sets the response content-type to application/json", context do
      assert_json_response(context.response)
    end

    test "it delegates the creation of the response body to the presenter", context do
      assert context.response.resp_body == "details about the scanning error"
    end
  end

  describe "payload for an original product" do
    setup do
      payload = %{
        "name" => "irrelevant",
        "price" => 1,
        "quantity" => 1,
        "from" => "2019-01-31T13:00:00.000000Z",
        "end" => "2019-02-01T13:00:00.000000Z"
      }

      product = %Product{
        name: "irrelevant",
        price: 1,
        quantity: 1,
        time_span: Interval.new(from: ~U[2019-01-31 13:00:00.000000Z], until: [days: 1])
      }

      stub(PayloadScanner.Stub, :scan, fn _ -> product end)
      expect(CreateProduct.Double, :create, fn ^product -> :ok end)
      stub(Presenter.Stub, :present, fn _ -> "empty body" end)

      [
        response:
          http_request(with_payload: payload)
          |> CreateProductController.create_product(
            with_scanner: PayloadScanner.Stub,
            with_usecase: CreateProduct.Double,
            with_presenter: Presenter.Stub
          )
      ]
    end

    test "it sends a response", context do
      assert context.response.state == :sent
    end

    test "it sets the response status to 201", context do
      assert context.response.status == 201
    end

    test "it delegates the creation of the response body to the presenter", context do
      assert context.response.resp_body == "empty body"
    end
  end

  describe "payload of a duplicate product" do
    setup do
      payload = %{
        "name" => "irrelevant",
        "price" => 1,
        "quantity" => 1,
        "from" => "2019-01-31T13:00:00.000000Z",
        "end" => "2019-02-01T13:00:00.000000Z"
      }

      product = %Product{
        name: "irrelevant",
        price: 1,
        quantity: 1,
        time_span: Interval.new(from: ~U[2019-01-31 13:00:00.000000Z], until: [days: 1])
      }

      stub(PayloadScanner.Stub, :scan, fn _ -> product end)
      stub(CreateProduct.Double, :create, fn _product -> :duplicate_product end)
      stub(Presenter.Stub, :present, fn _ -> "descriptive explanation" end)

      response =
        http_request(with_payload: payload)
        |> CreateProductController.create_product(
          with_scanner: PayloadScanner.Stub,
          with_usecase: CreateProduct.Double,
          with_presenter: Presenter.Stub
        )

      [response: response]
    end

    test "it sends a response", context do
      assert context.response.state == :sent
    end

    test "it responds with a 422 status", context do
      assert context.response.status == 422
    end

    test "it explains the error in the body of the response", context do
      assert context.response.resp_body == "descriptive explanation"
    end

    test "it sets the content-type header of the response to application/json", context do
      assert_json_response(context.response)
    end
  end

  describe "semantic error" do
    setup do
      payload = %{
        "name" => "irrelevant",
        "price" => 1,
        "quantity" => 1,
        "from" => "2019-01-31T13:00:00.000000Z",
        "end" => "2019-02-01T13:00:00.000000Z"
      }

      product = %Product{
        name: "irrelevant",
        price: 1,
        quantity: 1,
        time_span: Interval.new(from: ~U[2019-01-31 13:00:00.000000Z], until: [days: 1])
      }

      stub(PayloadScanner.Stub, :scan, fn _ -> product end)
      stub(CreateProduct.Double, :create, fn _product -> :invalid end)
      stub(Presenter.Stub, :present, fn _ -> "descriptive explanation" end)

      response =
        http_request(with_payload: payload)
        |> CreateProductController.create_product(
          with_scanner: PayloadScanner.Stub,
          with_usecase: CreateProduct.Double,
          with_presenter: Presenter.Stub
        )

      [response: response]
    end

    test "it sends a response", context do
      assert context.response.state == :sent
    end

    test "it responds with a 422 status", context do
      assert context.response.status == 422
    end

    test "it explains the error in the body of the response", context do
      assert context.response.resp_body == "descriptive explanation"
    end

    test "it sets the content-type header of the response to application/json", context do
      assert_json_response(context.response)
    end
  end
end
