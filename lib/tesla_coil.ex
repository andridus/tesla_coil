defmodule TeslaCoil do
  @moduledoc """
  Documentation for `TeslaCoil`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> TeslaCoil.hello()
      :world

  """
  defmacro __using__(_) do
    quote(do: use TeslaCoil.Router)
  end
end
