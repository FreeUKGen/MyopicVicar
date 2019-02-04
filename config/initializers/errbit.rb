ERRBIT = YAML.load_file("#{Rails.root.to_s}/config/errbit.yml")[Rails.env]


Airbrake.configure do |config|
  config.project_key = ERRBIT["api_key"]
  config.project_id = 1
  config.host    = ERRBIT["host"]
end