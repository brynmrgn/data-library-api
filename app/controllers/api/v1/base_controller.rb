# app/controllers/api/v1/base_controller.rb
#
# Base controller for API endpoints.
# Disables CSRF protection for API access.
#
module Api
  module V1
    class BaseController < ApplicationController
      #skip_before_action :verify_authenticity_token

      private

      def not_found
        render json: { error: "Not found" }, status: :not_found
      end
    end
  end
end
