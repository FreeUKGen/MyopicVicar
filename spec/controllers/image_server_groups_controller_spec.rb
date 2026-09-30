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

  describe "#image_server_group_params (strong parameters)" do
    def permitted(attrs)
      controller.params = ActionController::Parameters.new(image_server_group: attrs)
      controller.send(:image_server_group_params)
    end

    it "permits the form fields, custom_field as scalar or array, and strips the rest" do
      expect(permitted(group_name: "g", source_id: "s", origin: "allocate", custom_field: %w[1 2],
                       status: "c", source_start_date: "1800", number_of_images: 5).to_h.keys)
        .to contain_exactly("group_name", "source_id", "origin", "custom_field")
    end

    it "permits custom_field as a scalar (single-group initialize form)" do
      expect(permitted(custom_field: "1")[:custom_field]).to eq("1")
    end

    it "strips image_server_images_attributes" do
      result = permitted(group_name: "g", image_server_images_attributes: { "0" => { image_file_name: "x" } })
      expect(result.to_h.keys).to eq(["group_name"])
    end

    it "returns the same object each call so callers' assignments (assign_date) persist" do
      permitted(group_name: "g", syndicate_code: "SYN")
      controller.send(:image_server_group_params)[:assign_date] = "now"
      expect(controller.send(:image_server_group_params)[:assign_date]).to eq("now")
    end
  end
end
