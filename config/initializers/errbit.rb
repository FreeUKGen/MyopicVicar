ERRBIT = YAML.load_file("#{Rails.root.to_s}/config/errbit.yml")[Rails.env]


Airbrake.configure do |config|
  config.api_key = ERRBIT["api_key"]
  config.host    = ERRBIT["host"]
  config.port    = ERRBIT["port"]
  config.secure  = config.port == ERRBIT["secure"]
  config.ignore_only  = []
end