defmodule TeslaCoil.Test.Controller do
  def show(_, params) do
    %{body: build_message(params), status: 200}
  end

  def basic_post(_, params) do
    %{body: build_message(params), status: 200}
  end

  defp build_message(%{"target" => target}), do: %{message: "hello #{target}"}
  defp build_message(_), do: %{message: "hello"}
end
