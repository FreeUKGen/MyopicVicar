require "spec_helper"

RSpec.describe ManageSyndicatesController, type: :controller do
  before do
    allow(controller).to receive(:require_login)
    allow(controller).to receive(:get_user_info_from_userid)
    session[:syndicate] = "SYN"
  end

  {
    list_fully_transcribed_group: "No Fully Transcribed Image Groups Under This Syndicate",
    list_fully_reviewed_group: "No Fully Reviewed Image Groups Under This Syndicate"
  }.each do |action, notice|
    it "redirects an empty #{action} list to the syndicate image server page, not its referrer" do
      allow(ImageServerGroup).to receive(:group_ids_by_syndicate).and_return([[], [], {}])
      request.env["HTTP_REFERER"] = "http://test.host/manage_syndicates/SYN/#{action}"

      get action, params: { id: "SYN" }

      expect(response).to redirect_to(manage_image_group_manage_syndicate_path)
      expect(response.location).not_to eq(request.env["HTTP_REFERER"])
      expect(flash[:notice]).to eq(notice)
    end
  end
end
