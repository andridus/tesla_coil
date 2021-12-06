defmodule TeslaCoil do
  @moduledoc """
  Documentation for `TeslaCoil`.
  """

  defmacro __using__(_) do
    quote(do: use(TeslaCoil.Router))
  end
end
