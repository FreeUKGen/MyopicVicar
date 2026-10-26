
require 'securerandom'

secret_file = Rails.root.join("config", "secrets.yml")
mongo_config_file = Rails.root.join("config", "mongo_config.yml")

secret =
  ENV["SECRET_KEY_BASE"].presence ||
  ENV["SECRET_TOKEN"].presence ||
  begin
    YAML.safe_load_file(secret_file, aliases: true).to_h.dig(Rails.env.to_s, "secret_key_base")
  rescue Errno::ENOENT, Psych::SyntaxError, TypeError
    nil
  end&.to_s&.presence ||
  begin
    YAML.safe_load_file(secret_file, aliases: true).to_h.dig(Rails.env.to_s, "secret_token")
  rescue Errno::ENOENT, Psych::SyntaxError, TypeError
    nil
  end&.to_s&.presence ||
  begin
    YAML.safe_load_file(mongo_config_file, aliases: true).to_h.dig(Rails.env.to_s, "secret_key_base")
  rescue Errno::ENOENT, Psych::SyntaxError, TypeError
    nil
  end&.to_s&.presence

if secret.blank?
  if Rails.env.production?
    raise "Missing SECRET_KEY_BASE for #{Rails.env}. Set it in your environment or credentials."
  else
    secret = SecureRandom.hex(64)
    Rails.logger.warn <<~WARN
      No secret_key_base found for #{Rails.env}; generated a temporary local secret.
      Set SECRET_KEY_BASE or configure config/secrets.yml/config/mongo_config.yml for a stable value.
    WARN
  end
end

Rails.application.config.secret_token = secret
Rails.application.config.secret_key_base = secret
