defmodule Recom.Usecases.Shopkeeper do
  alias Recom.Entities.Product

  defmodule ProductsGateway do
    @callback store(Entities.Product.t()) ::
                {:ok, Entities.Product.t()} | {:error, :duplicate_product} | :error
  end

  defmodule Notifier do
    @callback notify_of_product_creation(Product.t()) :: :ok
  end

  defmodule ProductValidator do
    @callback validate(Product.t()) :: :valid | :invalid
  end

  defmodule CreateProduct do
    defmodule Behaviour do
      @type result :: :ok | :duplicate_product | :error | :validation_error
      @callback create(Product.t()) :: result
    end

    def create(product, deps) do
      gateway = deps[:with_gateway]
      notifier = deps[:with_notifier]

      if deps[:with_validator].validate(product) == :invalid do
        :validation_error
      else
        with {:ok, product} <- gateway.store(product),
             :ok <- notifier.notify_of_product_creation(product) do
          :ok
        else
          {:error, :duplicate_product} -> :duplicate_product
          :error -> :error
        end
      end
    end
  end
end
