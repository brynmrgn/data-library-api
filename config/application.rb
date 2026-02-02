require_relative "boot"

require "rails"
# Pick only the frameworks you need:
require "active_model/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_mailer/railtie" # Remove if not sending emails
require "action_view/railtie"
require "action_cable/engine" # Remove if not using WebSockets
# require "active_record/railtie" # <- Don't require this
# require "active_storage/engine" # <- Remove if not handling file uploads
# require "action_mailbox/engine" # <- Remove if not receiving emails
# require "action_text/engine" # <- Remove if not using rich text
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# we've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DataLibraryApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0
    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks generators])
    
    # Since it's an API, use this setting:
    config.api_only = true

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.log_level = :warn # In any environment initializer, or
    #Rails.logger.level = 0 # at any time
    config.assets.initialize_on_precompile = false if ENV['RAILS_ENV'] == 'production'

  end
end
