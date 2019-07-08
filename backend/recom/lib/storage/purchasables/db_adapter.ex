defmodule Recom.Storage.PurchasablesGateway.DbAdapter do
  @behaviour Recom.Usecases.Shopper.PurchasablesGateway
  @behaviour Recom.Usecases.Shopkeeper.CreateProduct.ProductsGateway

  use Timex

  import Ecto.Query

  alias Recom.Repo
  alias Recom.Storage
  alias Recom.Storage.PurchasablesGateway.DataMapper

  @impl true
  def all(instant) do
    try do
      purchasables =
        from(p in Storage.Product, where: p.end > ^instant)
        |> Repo.all()
        |> Enum.map(&DataMapper.convert/1)

      {:ok, purchasables}
    rescue
      _ -> :error
    end
  end

  @impl true
  def store(product) do
    %Storage.Product{
      name: product.name,
      price: product.price,
      quantity: product.quantity,
      start: Timex.to_datetime(product.time_span.from, "Etc/UTC"),
      end: Timex.to_datetime(product.time_span.until, "Etc/UTC")
    }
    |> Repo.insert()
  end
end
