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

RSpec.describe ManageCountiesController, type: :controller do
  include Devise::Test::ControllerHelpers

  describe 'GET manage_completion_submitted_image_group' do
    before do
      user = User.new(id: BSON::ObjectId.new, userid_detail_id: BSON::ObjectId.new.to_s)
      sign_in user
      allow(controller).to receive(:current_user).and_return(user)
    end

    it 'redirects with a status-specific notice when no image groups exist' do
      session[:chapman_code] = 'NFK'
      allow(controller).to receive(:get_user_info_from_userid)
      expect(ImageServerGroup).to receive(:group_ids_sort_by_place)
        .with('NFK', 'completion_submitted')
        .and_return([[], [], {}])

      get :manage_completion_submitted_image_group

      expect(response).to have_http_status(:redirect)
      expect(flash[:notice]).to eq("No image groups found with status of 'Completion Submitted'")
    end
  end
end
