require 'openssl'
require 'base64'
require 'time'

class SecurityHash
  SECRET = Rails.application.config.image_secret
  TOKEN_VALIDITY_SECONDS = Rails.application.config.validity
  
  def self.make_security_hash
    time = Time.now.to_i
    data = "#{time}:#{hmac_sha1_hex(time.to_s, SECRET)}"
    Base64.strict_encode64(data)
  end
  
  def self.hmac_sha1_hex(data, secret)
    OpenSSL::HMAC.hexdigest('SHA1', secret, data)
  end
  
  def self.verify_security_hash(token)
    return false if token.nil? || token.empty?
    
    begin
      decoded = Base64.strict_decode64(token)
      time_str, signature = decoded.split(':', 2)
      
      return false if time_str.nil? || signature.nil?
      
      expected_signature = hmac_sha1_hex(time_str, SECRET)
      return false unless signature == expected_signature #validate signature
      
      token_time = time_str.to_i
      current_time = Time.now.to_i
      
      (current_time - token_time) <= TOKEN_VALIDITY_SECONDS #validate token age
    rescue => e
      false
    end
  end
  
  def self.sign_data(data)
    OpenSSL::HMAC.hexdigest('SHA1', SECRET, data)
  end
  
  def self.verify_signature(data, signature)
    expected_signature = sign_data(data)
    signature == expected_signature
  end
end