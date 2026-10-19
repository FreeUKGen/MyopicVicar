require "spec_helper"

RSpec.describe ImageServerGroupsController, type: :controller do
  before do
    allow(controller).to receive(:require_login)
  end

  describe "POST send_complete_to_cc" do
    it "emails every selected group once, transitions via the existing model method, and redirects to the syndicate image server page" do
      session[:syndicate] = "SYN"
      user = double("user")
      place = double("place", chapman_code: "NFK")
      allow(controller).to receive(:display_info) do
        controller.instance_variable_set(:@user, user)
        controller.instance_variable_set(:@place, place)
      end
      expect(ImageServerGroup).to receive(:email_cc_completion).with("group-1", "NFK", user).once
      expect(ImageServerGroup).to receive(:email_cc_completion).with("group-2", "NFK", user).once

      post :send_complete_to_cc, params: { completed_groups: ["group-1", "group-2"] }

      expect(response).to redirect_to(manage_image_group_manage_syndicate_path)
      expect(flash[:notice]).to eq("Email sent to County Coordinator")
    end
  end

  describe "PUT update" do
    it "uses the existing bulk completion update and redirects to the county image server page" do
      user = double("user")
      relation = double("relation", first: double("image server group"))
      allow(controller).to receive(:get_user).and_return(user)
      allow(ImageServerGroup).to receive(:id).with("group-1").and_return(relation)
      expect(ImageServerGroup).to receive(:update_put_request).with(
        hash_including("type" => "complete", "completed_groups" => ["group-1", "group-2"]),
        user
      ).and_return("updated")

      put :update, params: { id: "group-1", _method: "put", type: "complete", completed_groups: ["group-1", "group-2"] }

      expect(response).to redirect_to(manage_image_group_manage_county_path)
      expect(flash[:notice]).to eq("updated")
    end
  end
end
