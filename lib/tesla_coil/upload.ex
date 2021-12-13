defmodule TeslaCoil.Upload do
  @derive Jason.Encoder

  defstruct filename: nil,
            content: nil

  @type t :: %__MODULE__{
          filename: String.t(),
          content: String.t()
        }
end
