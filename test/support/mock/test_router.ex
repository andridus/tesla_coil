defmodule TeslaCoil.Test.Router do
  use TeslaCoil.Router

  scope "https://tesla.com", TeslaCoil.Test do
    get "/mock", Controller, :show
    post "/mock", Controller, :basic_post
  end
end
