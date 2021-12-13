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

  test "multipart atomic key sent" do
    body =
      Multipart.new()
      |> Multipart.add_field(:atomic_key, "value")

    request = post!("https://tesla.com/multipart", body)

    assert request.body == %{"atomic_key" => "value"}
  end

  test "multipart nesting" do
    # I've put everything togheter instead of making a test for every case
    # as a way to also test if it works when everything is put together.
    # Maybe i should also do individual tests for every case eventually.

    body =
      Multipart.new()
      |> Multipart.add_field("keyless_array[]", "first")
      |> Multipart.add_field("array_with_keys[5]", "fourth")
      |> Multipart.add_field("array_with_keys[0]", "first")
      |> Multipart.add_field("array_with_keys[1][apple]", "red")
      |> Multipart.add_field("array_with_keys[1][lemon]", "green")
      |> Multipart.add_field("keyless_array[]", "second")
      |> Multipart.add_field("map[lemon]", "green")
      |> Multipart.add_field("array_with_keys[2]", "third")
      |> Multipart.add_field("map[apple]", "red")
      |> Multipart.add_field("map[array][]", "first")
      |> Multipart.add_field("map[array][]", "second")

    request = post!("https://tesla.com/multipart", body)

    assert request.body == %{
             "array_with_keys" => [
               "first",
               %{"apple" => "red", "lemon" => "green"},
               "third",
               "fourth"
             ],
             "keyless_array" => ["first", "second"],
             "map" => %{"apple" => "red", "array" => ["first", "second"], "lemon" => "green"}
           }
  end

  @file_path "test/support/mock/mocked_file.txt"
  test "multipart upload" do
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
