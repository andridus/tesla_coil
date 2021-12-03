defmodule TeslaCoil.RouterTest do
  use ExUnit.Case
  use Tesla

  adapter(Tesla.Mock)

  plug(Tesla.Middleware.JSON)

  doctest TeslaCoil.Router

  setup do
    Tesla.Mock.mock(&TeslaCoil.Test.Router.request/1)
  end

  test "get request uses query params" do
    request = get!("https://tesla.com/mock?target=world")

    assert request.body == %{message: "hello world"}
  end

  test "non 'get' request uses body params" do
    request = post!("https://tesla.com/mock", %{target: "world"})
    assert request.body == %{message: "hello world"}
  end
end
