require "spec_helper"

RSpec.shared_examples "a bulk image-group email form" do
  before do
    session[:syndicate] = "SYN"
    assign(:group_ids, [["group-1"], ["group-2"]])
    assign(:completed_groups, ["group-1", "group-2"])
    allow(view).to receive(:render).and_call_original
    allow(view).to receive(:render).with(partial: "flash_notice").and_return("")
    allow(view).to receive(:render).with(
      partial: "image_groups",
      locals: { image_group_filter: kind_of(String) }
    ).and_return("")
  end

  it "posts group ids in the request body rather than the URL" do
    render

    expect(rendered).to include(%(action="#{send_complete_to_cc_image_server_groups_path}"))
    expect(rendered).to include(%(method="post"))
    expect(rendered).to include(%(name="completed_groups[]" value="group-1"))
    expect(rendered).to include(%(name="completed_groups[]" value="group-2"))
    expect(rendered).not_to include("?completed_groups")
  end
end

RSpec.describe "manage_syndicates/list_fully_transcribed_group.html.erb", type: :view do
  it_behaves_like "a bulk image-group email form"
end

RSpec.describe "manage_syndicates/list_fully_reviewed_group.html.erb", type: :view do
  it_behaves_like "a bulk image-group email form"
end
