defmodule TeslaCoil.Router do
  @moduledoc """
  Defines a router for Tesla mock
  """

  @http_methods [:get, :post, :put, :patch, :delete, :options, :connect, :trace, :head]

  @field_root_pattern ~r/([\w|\d]+)(\[.*\])*/
  @field_nesting_pattern ~r/\[([\w|\d]*)\]/

  defmacro scope(path, alias_ \\ nil, do: block) do
    quote do
      path = unquote(path) |> String.replace(~r/\/$/, "")
      alias_ = unquote(alias_)

      Module.get_attribute(__MODULE__, :__scope_path__)
      |> case do
        nil ->
          path
          |> URI.parse()
          |> Map.get(:host)
          |> unless do
            raise "Root path should have at least scheme and domain"
          end

          # define scope block path and alias
          @__scope_path__ [path]
          @__scope_alias__ alias_

          # execute scope block
          unquote(block)

          # quit root scope
          Module.delete_attribute(__MODULE__, :__scope_path__)

        parent_path ->
          parent_alias = @__scope_alias__

          # define scope block path and alias
          @__scope_path__ parent_path ++ [path]
          @__scope_alias__ [parent_alias, alias_] |> Module.concat()

          # execute scope block
          unquote(block)

          # return attributes to what it was in the parent scope to effectively exit current scope
          @__scope_path__ parent_path
          @__scope_alias__ parent_alias
      end
    end
  end

  def path_pattern(path) do
    path
    |> String.replace(~r/\/$/, "")
    |> then(&"^#{&1}\/?(\\?.*)?$")
    |> String.replace(~r/\/:([\w|\d]*)/, "/(?<\\g{1}>[\\w|\\d|-]*)")
    |> Regex.compile!()
  end

  defmacro new_route(method, path, alias_, function) do
    [bind_quoted: [method: method, path: path, alias_: alias_, function: function]]
    |> quote do
      Module.get_attribute(__MODULE__, :__scope_path__)
      |> case do
        nil ->
          raise "should be used inside a scope block"

        scope_path ->
          pattern =
            scope_path
            |> Kernel.++([path])
            |> Enum.join("")
            |> path_pattern()

          controller = Module.concat(@__scope_alias__, alias_)

          @__route_accumulator__ %{
            method: method,
            pattern: pattern,
            controller: controller,
            function: function
          }
      end
    end
  end

  @http_methods
  |> Enum.each(fn method_ ->
    defmacro unquote(method_)(path, alias_, function) do
      method = unquote(method_)

      [bind_quoted: [method: method, path: path, alias_: alias_, function: function]]
      |> quote(do: new_route(method, path, alias_, function))
    end
  end)

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :__route_accumulator__, accumulate: true)
    end
  end

  defmacro request(env) do
    quote do
      env = unquote(env)

      @__routes__
      |> Enum.find(fn route ->
        route.method == env.method && env.url |> String.match?(route.pattern)
      end)
      |> case do
        nil ->
          raise "URL \"#{env.url}\" don't match any mocked route"

        route ->
          args =
            if env.method == :get do
              env.url
              |> URI.parse()
              |> Map.get(:query)
              |> Kernel.||("")
              |> URI.decode_query()
            else
              handle_body(env)
            end
            |> Map.merge(Regex.named_captures(route.pattern, env.url))

          apply(route.controller, route.function, [env, args])
          |> case do
            %{body: body, status: status} = result -> env |> Map.merge(result)
            %{body: _} -> raise "Mocked response must have a :status key"
            %{} -> raise "Mocked response must have a :body key"
            _ -> raise "Mocked response must be a map with :body and :status keys"
          end
      end
    end
  end

  defmacro handle_body(env) do
    quote do
      env = unquote(env)

      case env.body do
        %Tesla.Multipart{} -> multipart_to_params(env.body)
        _ -> env.body |> Jason.decode!()
      end
    end
  end

  defmacro multipart_to_params(body) do
    quote do
      unquote(body).parts
      |> Enum.map(fn part ->
        cond do
          match?(%File.Stream{}, part.body) ->
            %{
              "filename" => part.dispositions[:filename],
              "content" => File.read!(part.body.path)
            }

          part.dispositions[:filename] ->
            %{
              "filename" => part.dispositions[:filename],
              "content" => part.body
            }

          :else ->
            part.body
        end
        |> then(&{part.dispositions[:name], &1})
      end)
      |> structure_params()
    end
  end

  def structure_params(items) do
    items
    |> extract_paths()
    |> build_tree()
  end

  defp extract_paths(fields) do
    fields
    |> Enum.map(fn {raw_key, value} ->
      [[field | raw_nesting]] = Regex.scan(@field_root_pattern, raw_key, capture: :all_but_first)

      nesting =
        case raw_nesting do
          [] ->
            []

          [string] ->
            Regex.scan(@field_nesting_pattern, string, capture: :all_but_first) |> List.flatten()
        end

      {field, nesting, value}
    end)
  end

  defp build_tree(list) do
    list
    |> group_by_nesting()
    |> Enum.map(&handle_nesting/1)
    |> finish_structure()
  end

  defp group_by_nesting(list) do
    list
    |> Enum.group_by(&elem(&1, 0), fn
      {"", [], value} -> value
      {_, [], value} -> {:leaf_node, value}
      {_, nesting, value} -> {nesting, value}
    end)
  end

  defp handle_nesting({"", list}), do: {"", list}
  defp handle_nesting({k, [leaf_node: value]}), do: {k, value}
  defp handle_nesting({k, list}), do: {k, list |> structure_nested()}

  defp structure_nested(list) do
    list
    |> Enum.map(fn {[field | nesting], value} -> {field, nesting, value} end)
    |> build_tree()
  end

  defp finish_structure([{"", list}]), do: list

  defp finish_structure(list) do
    if numeral_keys?(list), do: list |> Enum.map(&elem(&1, 1)), else: list |> Map.new()
  end

  defp numeral_keys?(list), do: list |> Enum.all?(&(&1 |> elem(0) |> String.match?(~r/^\d+$/)))

  defmacro __before_compile__(_) do
    quote do
      @__routes__ @__route_accumulator__ |> Enum.reverse()

      def routes, do: @__routes__
      def request(env), do: unquote(__MODULE__).request(env)
    end
  end
end
