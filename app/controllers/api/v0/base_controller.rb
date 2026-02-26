# app/controllers/api/v0/base_controller.rb
#
# Base controller for the v0 (LDA compatibility) API namespace.
#
module Api
  module V0
    class BaseController < ApplicationController
      private

      def not_found
        render json: { error: "Not found" }, status: :not_found
      end
    end
  end
end
