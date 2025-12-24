class HomeController < ApplicationController
  def index
    render json: {
      name: "UK Parliament Data Library API",
      current_version: "v1",
      api_root: "#{request.base_url}/api/v1"
    }
  end
end