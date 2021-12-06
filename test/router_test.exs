defmodule TeslaCoil.RouterTest do
  use ExUnit.Case
  use Tesla

  adapter(Tesla.Mock)

  plug(Tesla.Middleware.JSON)

  doctest TeslaCoil.Router

  setup do
    Tesla.Mock.mock(&TeslaCoil.Test.Router.request/1)
  end

  # =========================================================
  #                  PATH CONTEXT
  # =========================================================

  test "scope with only a slash in its path just inherts the path" do
    request = get!("https://tesla.com/directory/same-directory")
    assert request.body == %{message: "hello"}
  end

  test "trailing slash on route definition don't disturbs scope inheritance" do
    request = get!("https://tesla.com/directory/trailing-slash")
    assert request.body == %{message: "hello"}
  end

  test "trailing slash on url don't prevent route match" do
    request = get!("https://tesla.com/mock/")
    assert request.body == %{message: "hello"}
  end

  # ===============================================================
  #                     PARAMS CONTEXT
  # ===============================================================

  test "non 'get' request uses body params" do
    request = post!("https://tesla.com/mock", %{target: "world"})
    assert request.body == %{message: "hello world"}
  end

  test "'get' request uses query params" do
    request = get!("https://tesla.com/mock?target=world")
    assert request.body == %{message: "hello world"}
  end

  test "'get' request without query works anyway" do
    request = get!("https://tesla.com/")
    assert request.body == %{message: "hello"}
  end

  test "simple path params" do
    request = get!("https://tesla.com/path-param/world")
    assert request.body == %{message: "hello world"}
  end

  test "path params with numbers" do
    request = get!("https://tesla.com/path-param/with-number/world")
    assert request.body == %{message: "hello world"}
  end

  # ========================================================================
end
