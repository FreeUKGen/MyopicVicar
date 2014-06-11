# lib/devise/encryptors/md5.rb
require 'digest/md5'

module Devise
  module Encryptable
    module Encryptors
      class Freereg < Base
        OUR_SECRET_KEY = 'secret key goes here'
        
        def self.digest(password, stretches, salt, pepper)
          crypted_password = hex_to_base64_digest(OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('md5'),  OUR_SECRET_KEY, password))
          crypted_password.sub(/==$/, '')
       end
        

        def self.hex_to_base64_digest(hexdigest)
          [[hexdigest].pack("H*")].pack("m").strip
        end
        
      end
    end
  end
end

# 

# pass =  hex_to_base64_digest(OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('md5'), secret key, my_password))
