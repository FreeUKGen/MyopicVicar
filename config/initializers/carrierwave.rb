	require 'rails'
	require 'carrierwave/mongoid'
    CarrierWave.configure do |config|
    #config.root = Rails.application.config.datafiles
    config.permissions = 0666
    config.directory_permissions = 0777
    config.cache_dir = '/tmp/carrierwave'
    end  