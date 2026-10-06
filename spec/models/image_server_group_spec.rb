require "spec_helper"

RSpec.describe ImageServerGroup, type: :model do
  describe ".email_cc_completion" do
    it "marks the group completion submitted and sends one email" do
      group = double("group criteria")
      delivery = double("delivery")
      allow(described_class).to receive(:where).with(id: "group-1").and_return(group)
      expect(ImageServerImage).to receive(:update_image_status).with(group, "cs").once
      expect(UserMailer).to receive(:notify_cc_assignment_complete)
        .with("user", "group-1", "NFK").once.and_return(delivery)
      expect(delivery).to receive(:deliver_now).once

      described_class.email_cc_completion("group-1", "NFK", "user")
    end
  end

  describe ".update_put_request" do
    it "marks every selected group completed" do
      initial = double("initial relation", first: double("initial group"))
      group_1 = double("group 1 relation")
      group_2 = double("group 2 relation")
      allow(described_class).to receive(:id).with("group-1").and_return(initial, group_1)
      allow(described_class).to receive(:id).with("group-2").and_return(group_2)
      expect(group_1).to receive(:update_image_and_group_for_put_request).with("r", "c").once
      expect(group_2).to receive(:update_image_and_group_for_put_request).with("r", "c").once

      described_class.update_put_request(
        { id: "group-1", type: "complete", completed_groups: ["group-1", "group-2"] },
        "user"
      )
    end
  end
end
