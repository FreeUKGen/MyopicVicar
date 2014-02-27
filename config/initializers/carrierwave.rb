	require 'rails'
	require 'carrierwave/mongoid'
    CarrierWave.configure do |config|
    #config.root = Rails.application.config.datafiles
    config.cache_dir = '/tmp/carrierwave'
    end  