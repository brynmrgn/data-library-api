# app/controllers/home_controller.rb
#
# Handles the root URL (/). Returns basic API information and
# directs clients to the versioned API root at /api/v1.
#
class HomeController < ApplicationController
  # Returns API name, current version, and link to the versioned API root
  #
  def index
    render json: {
      name: "UK Parliament Linked Data API",
      current_version: "v1",
      api_root: "#{request.base_url}/api/v1"
    }
  end
end