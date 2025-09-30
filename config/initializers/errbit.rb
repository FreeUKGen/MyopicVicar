begin

  # at some point `airbrake-ruby` gem defaulted to fetching configuration from
  # a remote host that would immediately(*) override `config.errors_notifications`
  #
  # (*) well, intermittently, depending on whether the fetch succeeds, maybe
  #
  # later `airbrake-ruby` gems provide `config.remote_config` to disable this,
  # ... but not our current version
  #
  # here we disable the method directly
  class Airbrake::Config::Processor
    def process_remote_configuration
      Rails.logger.info "Airbrake remote configuration disabled"
    end
  end

  ERRBIT = YAML.load_file("#{Rails.root.to_s}/config/errbit.yml")[Rails.env]

  if ERRBIT && ERRBIT['api_key'].present?
    Airbrake.configure do |config|
      config.project_key         = ERRBIT['api_key']
      config.project_id          = 1
      config.host                = ERRBIT['host']
      config.environment         = Rails.env
      config.ignore_environments = %w[test]
      config.logger              = Rails.logger
    end

    Rails.logger.info "Errbit configured successfully for #{Rails.env}"
  else
    Rails.logger.warn "Errbit not configured - missing API key for #{Rails.env}"
  end

rescue => e
  Rails.logger.error "Failed to configure Errbit: #{e.message}"
end
