class FreebmdDbBase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection FREEBMD_DB
end