Mongoid.configure do |config|
#  binding.pry
#  config.database = Mongo::Connection.new.db("mvui-#{Rails.env}")
  #config.database.authenticate(username,password)
end

# Apply string trimming to all Mongoid models by default
Rails.application.config.to_prepare do
  Mongoid::Document.include(StripStringFields) unless Mongoid::Document.included_modules.include?(StripStringFields)
end
