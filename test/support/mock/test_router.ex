defmodule TeslaCoil.Test.Router do
  use TeslaCoil.Router

  scope "https://tesla.com", TeslaCoil.Test do
    get "/", Controller, :default
    post "/", Controller, :default

    get "/path-param/:target", Controller, :default
    get "/path-param/with-number/:target_1", Controller, :path_param_with_number
    get "/file/:filename", Controller, :file
    post "/multipart", Controller, :multipart

    scope "/directory" do
      scope "/trailing-slash/" do
        get "/", Controller, :default
      end

      scope "/" do
        get "/same-directory", Controller, :default
      end
    end
  end
end
