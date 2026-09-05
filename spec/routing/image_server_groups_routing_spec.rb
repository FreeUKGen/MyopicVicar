require "spec_helper"

RSpec.describe ImageServerGroupsController, type: :routing do
  it "routes bulk completion email through POST without a group id" do
    expect(post: "/image_server_groups/send_complete_to_cc").to route_to(
      controller: "image_server_groups",
      action: "send_complete_to_cc"
    )
    expect(get: "/image_server_groups/group-1/send_complete_to_cc").to route_to(
      controller: "image_server_groups",
      action: "send_complete_to_cc",
      id: "group-1"
    )
    expect(get: "/image_server_groups/send_complete_to_cc").not_to route_to(
      controller: "image_server_groups",
      action: "send_complete_to_cc"
    )
  end
end
