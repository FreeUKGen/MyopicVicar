# Parameters below updated to be compatabile with Airbrake gem version 5.0

errbit_config = "./config/errbit.yml"

if File.exist?(errbit_config) 
    ERRBIT = YAML.load_file("#{Rails.root.to_s}/config/errbit.yml")[Rails.env]
    Airbrake.configure do |config|
     config.host = ERRBIT["host"]
     config.project_id = ERRBIT["project_id"] # required, but any positive integer works
     config.project_key = ERRBIT["project_key"] # required, but any string of integers works 
   end
  else 
    Airbrake.configure do |config|
     config.host = ""
     config.project_id = 1
     config.project_key = "1"
    end
end 