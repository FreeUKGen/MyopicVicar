# Copyright 2012 Trustees of FreeBMD
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Be sure to restart your server when you modify this file.
#
# Mongoid-backed sessions keep the browser cookie small (session id only) and
# prevent oversized Cookie headers when validations and admin flows store many
# keys or long URLs in session.
MongoSessionStore.collection_name = 'rails_sessions'

cfg = MyopicVicar::Application.config
expiry_time = (cfg.respond_to?(:server_upgrade) && cfg.server_upgrade) ? 3.seconds : nil

case MyopicVicar::Application.config.freexxx_display_name
when 'FreeCEN'
  MyopicVicar::Application.config.session_store :mongoid_store,
                                                  key: 'FreeCEN_session',
                                                  expire_after: expiry_time
when 'FreeREG'
  MyopicVicar::Application.config.session_store :mongoid_store,
                                                  key: 'FreeREG_session',
                                                  expire_after: expiry_time
when 'FreeBMD'
  MyopicVicar::Application.config.session_store :mongoid_store,
                                                  key: 'FreeBMD_session',
                                                  expire_after: nil
end
