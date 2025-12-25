# config/initializers/resource_config.rb
# Load the generated resource config
resource_config_path = Rails.root.join('config', 'resource_config.rb')
require resource_config_path if File.exist?(resource_config_path)
