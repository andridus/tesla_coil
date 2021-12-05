defmodule TeslaCoil.Test.Router do
  use TeslaCoil.Router

  scope "https://tesla.com", TeslaCoil.Test do
    get "/mock", Controller, :default_success
    post "/mock", Controller, :default_success

    get "/path-param/:target", Controller, :default_success
    get "/path-param/with-number/:target_1", Controller, :path_param_with_number

    scope "/directory/" do
      get "/trailing-slash", Controller, :default_success
    end
  end
end
