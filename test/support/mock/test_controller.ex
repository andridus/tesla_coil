defmodule TeslaCoil.Test.Controller do
  def default_success(_, params), do: %{body: build_message(params), status: 200}

  defp build_message(%{"target" => target}), do: %{message: "hello #{target}"}
  defp build_message(_), do: %{message: "hello"}
end
