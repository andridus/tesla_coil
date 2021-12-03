defmodule TeslaCoil.Router do
  @moduledoc """
  Defines a router for Tesla mock
  """

  @http_methods [:get, :post, :put, :patch, :delete, :options, :connect, :trace, :head]

  defmacro scope(path, alias_ \\ nil, do: block) do
    quote do
      alias_ = unquote(alias_)

      Module.get_attribute(__MODULE__, :__scope_path__)
      |> case do
        nil ->
          unquote(path)
          |> URI.parse()
          |> case do
            %{host: nil} ->
              raise "Primary scope must be a base path with at least scheme (e.g.: 'https://') and domain"

            _ ->
              @__scope_path__ [unquote(path)]
              @__scope_alias__ alias_

              unquote(block)

              Module.delete_attribute(__MODULE__, :__scope_path__)
          end

        parent_scope ->
          @__scope_path__ parent_scope ++ [unquote(path)]

          scope_alias_ = @__scope_alias__

          @__scope_alias__ [@__scope_alias__, alias_] |> Module.concat()

          unquote(block)

          @__scope_path__ parent_scope
          @__scope_alias__ scope_alias_
      end
    end
  end

  def path_pattern(path) do
    "^#{path}(\\?.*)?$"
    |> String.replace(~r/\/:(\w*)/, "/(?<\\g{1}>[\\w|\\d|-]*)")
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
    quote bind_quoted: [env: env] do
      @__routes__
      |> Enum.find(fn route ->
        route.method == env.method && env.url |> String.match?(route.pattern)
      end)
      |> case do
        nil ->
          raise "URL \"#{env.url}\" is not mocked"

        route ->
          args =
            if env.method == :get do
              env.url
              |> URI.parse()
              |> Map.get(:query)
              |> URI.decode_query()
            else
              env.body
              |> Jason.decode!()
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

  defmacro __before_compile__(_) do
    quote do
      @__routes__ @__route_accumulator__ |> Enum.reverse()

      def routes, do: @__routes__
      def request(env), do: unquote(__MODULE__).request(env)
    end
  end
end
