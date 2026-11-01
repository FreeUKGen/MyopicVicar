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
  render_views
  describe 'GET internal_server_error' do
    let(:exception) { RuntimeError.new('private failure') }
    let(:logger) { Rails.logger }

    before do
      request.env['action_dispatch.exception'] = exception
      request.env['action_dispatch.original_path'] = '/problem'
      request.env['QUERY_STRING'] = 'source=original'
      request.env['REMOTE_ADDR'] = '203.0.113.12'
      request.env['action_dispatch.request_id'] = 'request-123'
      allow_any_instance_of(ActionController::TestRequest).to receive(:request_id).and_return('request-123')
      session[:userid_detail_id] = 'abc123'

      allow(logger).to receive(:error)
      allow(Socket).to receive(:gethostname).and_return('test-host')
      allow(UseridDetail).to receive(:id).with('abc123').and_return(double(first: double(userid: 'testuserid')))
    end

    it 'renders public-safe error details' do
      get :internal_server_error

      expect(response.status).to eq(500)
      expect(response.body).to include('http://test.host/problem?source=original')
      expect(response.body).to include('testuserid')
      expect(response.body).to include('203.0.113.12')
      expect(response.body).to include('test-host')
      expect(response.body).to include("We're sorry, but something went wrong while processing your request. Please return to your previous activity but try to avoid doing the exact same action again. If you wish to send in an error report, please copy or take a screenshot of the following information:")
      expect(response.body).to include('If you wish to send in an error report')
      expect(response.body).not_to include('sent to the webmaster')
      expect(response.body).not_to include('RuntimeError')
      expect(response.body).not_to include('private failure')
      expect(response.body).not_to include('/500')
    end

    it 'identifies an anonymous request' do
      session.delete(:userid_detail_id)

      get :internal_server_error

      expect(response.body).to include('Userid')
      expect(response.body).to include('Not logged in')
    end

    it 'recovers a userid from the signed legacy cookie' do
      session.delete(:userid_detail_id)
      cookies.signed[:userid] = 'cookie123'
      allow(UseridDetail).to receive(:id).with('cookie123').and_return(double(first: double(userid: 'cookieuserid')))

      get :internal_server_error

      expect(response.body).to include('cookieuserid')
      expect(response.body).not_to include('cookie123')
    end

    it 'shows unavailable instead of an identifier when userid lookup fails' do
      session[:userid_detail_id] = 'database-id'
      allow(UseridDetail).to receive(:id).with('database-id').and_raise(IOError)

      get :internal_server_error

      expect(response.body).to include('Userid')
      expect(response.body).to include('Unavailable')
      expect(response.body).not_to include('database-id')
    end

    it 'does not duplicate a query string already present in the original path' do
      request.env['action_dispatch.original_path'] = '/problem?source=original'

      get :internal_server_error

      expect(response.body.scan('source=original').length).to eq(1)
    end

    it 'logs the diagnostic error details' do
      get :internal_server_error

      expect(logger).to have_received(:error).with(
        a_string_including(
          'URL=http://test.host/problem?source=original',
          'USERID=testuserid',
          'CLIENT_IP=203.0.113.12',
          'SERVER_HOSTNAME=test-host',
          'REQUEST_ID=request-123'
        )
      ).once
    end

    it 'sanitizes newlines in diagnostic log values' do
      request.env['action_dispatch.original_path'] = "/problem\nFAKE_FIELD=injected"

      get :internal_server_error

      expect(logger).to have_received(:error).with(
        a_string_including('URL=http://test.host/problem FAKE_FIELD=injected')
      )
      expect(logger).not_to have_received(:error).with(a_string_including("\n"))
    end

    it 'still renders when URL or client IP resolution fails' do
      allow_any_instance_of(ActionController::TestRequest).to receive(:protocol).and_raise(StandardError)
      allow_any_instance_of(ActionController::TestRequest).to receive(:remote_ip).and_raise(StandardError)

      expect { get :internal_server_error }.not_to raise_error
      expect(response.status).to eq(500)
      expect(response.body).to include('Unavailable')
    end

    it 'still renders when hostname lookup and logging fail' do
      allow(Socket).to receive(:gethostname).and_raise(SocketError)
      allow(logger).to receive(:error).and_raise(IOError)

      expect { get :internal_server_error }.not_to raise_error
      expect(response.status).to eq(500)
      expect(response.body).to include('Server hostname')
      expect(response.body).to include('Unavailable')
    end
  end
end
