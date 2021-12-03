defmodule TeslaCoil.Test.Controller do
  @default_response %{body: %{message: "hello"}, status: 200}

  def show(_, params) do
    %{body: build_message(params), status: 200}
  end

  def basic_post(_, params) do
    %{body: build_message(params), status: 200}
  end

  def trailing_slash(_, _), do: @default_response

  defp build_message(%{"target" => target}), do: %{message: "hello #{target}"}
  defp build_message(_), do: %{message: "hello"}
end
