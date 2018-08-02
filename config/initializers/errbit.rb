ERRBIT = YAML.load_file("#{Rails.root.to_s}/config/errbit.yml")[Rails.env]

# Parameters below updated to be compatabile with Airbrake gem version 5.0

Airbrake.configure do |config|
  config.host = ERRBIT["host"]
  config.project_id = ERRBIT["project_id"] # required, but any positive integer works
  config.project_key = ERRBIT["project_key"]
end
