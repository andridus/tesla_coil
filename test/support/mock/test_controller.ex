defmodule TeslaCoil.Test.Controller do
  def default(_, params), do: %{body: build_body(params), status: 200}

  def path_param_with_number(_, params) do
    message = params["target_1"] |> build_body()

    %{body: message, status: 200}
  end

  def multipart(_, params) do
    %{body: params, status: 200}
  end

  def file(_, params) do
    %{body: params, status: 200}
  end

  def plain_text_result(_, _), do: %{body: "some random text", status: 200}

  defp build_body(%{"target" => target}), do: %{message: "hello #{target}"}
  defp build_body(%{"_json" => target}), do: %{message: "hello #{target}"}
  defp build_body(target) when is_binary(target), do: %{message: "hello #{target}"}
  defp build_body(_), do: %{message: "hello"}
end
