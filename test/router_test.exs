defmodule TeslaCoil.RouterTest do
  use ExUnit.Case
  use Tesla

  alias Tesla.Multipart

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
    request = get!("https://tesla.com/")
    assert request.body == %{message: "hello"}
  end

  # ===============================================================
  #                     PARAMS CONTEXT
  # ===============================================================

  test "non 'get' request uses body params" do
    request = post!("https://tesla.com", %{target: "world"})
    assert request.body == %{message: "hello world"}
  end

  test "'get' request uses query params" do
    request = get!("https://tesla.com?target=world")
    assert request.body == %{message: "hello world"}
  end

  test "'get' request without query works anyway" do
    request = get!("https://tesla.com")
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

  @file_path "test/support/mock/mocked_file.txt"
  test "multipart body" do
    body =
      Multipart.new()
      |> Multipart.add_field("hello", "world")
      |> Multipart.add_file(@file_path, name: "mocked_file", filename: "loaded_file.txt")
      |> Multipart.add_file_content("built content", "built_file.txt", name: "mocked_file_content")

    request = post!("https://tesla.com/multipart", body)

    assert request.body == %{
             "hello" => "world",
             "mocked_file" => %{"content" => "loaded content", "filename" => "loaded_file.txt"},
             "mocked_file_content" => %{
               "content" => "built content",
               "filename" => "built_file.txt"
             }
           }
  end

  # ========================================================================
end
