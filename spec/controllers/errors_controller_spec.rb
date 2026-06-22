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
require 'spec_helper'

RSpec.describe ErrorsController, type: :controller do
  describe 'GET internal_server_error' do
    let(:exception) { RuntimeError.new('private failure') }
    let(:logger) { instance_double(ActiveSupport::Logger, error: true) }

    before do
      request.env['action_dispatch.exception'] = exception
      request.env['action_dispatch.original_path'] = '/problem'
      request.env['QUERY_STRING'] = 'source=original'
      request.env['REMOTE_ADDR'] = '203.0.113.12'
      session[:userid_detail_id] = 'abc123'

      allow(Rails).to receive(:logger).and_return(logger)
      allow(Socket).to receive(:gethostname).and_return('test-host')
      allow(UseridDetail).to receive(:id).with('abc123').and_return(double(first: double(userid: 'testuserid')))
    end

    it 'renders public-safe error details' do
      get :internal_server_error

      expect(response.status).to eq(500)
      expect(response.body).to include('http://test.host/problem?source=original')
      expect(response.body).to include('testuserid')
      expect(response.body).to include('test-host')
      expect(response.body).not_to include('RuntimeError')
      expect(response.body).not_to include('private failure')
      expect(response.body).not_to include('203.0.113.12')
    end

    it 'logs the diagnostic error details' do
      get :internal_server_error

      expect(logger).to have_received(:error).with(
        a_string_including(
          'URL=http://test.host/problem?source=original',
          'USERID=testuserid',
          'CLIENT_IP=203.0.113.12',
          'SERVER_HOSTNAME=test-host',
          'EXCEPTION_CLASS=RuntimeError',
          'EXCEPTION_MESSAGE=private failure'
        )
      )
    end
  end
end
