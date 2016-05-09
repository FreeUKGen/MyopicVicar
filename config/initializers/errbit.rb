ERRBIT = YAML.load_file("#{Rails.root.to_s}/config/errbit.yml")[Rails.env]

Airbrake.configure do |config|
  config.environment = Rails.env
  config.ignore_environments = %w(development test)
  
  config.project_key = ERRBIT["api_key"]
  config.project_id = 1
  config.host    = ERRBIT["host"]
  # config.port    = ERRBIT["port"]
  # config.secure  = config.port == ERRBIT["secure"]
  # config.ignore_only  = []
end
