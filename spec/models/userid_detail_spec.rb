require 'spec_helper'

describe UseridDetail do
  subject { described_class.new() }  

  describe '#list_incomplete_registrations' do
    let (:current_user) {UseridDetail.where(userid: "VinodhiniS").first}

    it "is a Array" do
      expect(subject.list_incomplete_registrations(current_user)).to be_a Array
    end

    it "gives count as 103" do
      expect(subject.list_incomplete_registrations(current_user).count).to eq 103
    end
  end

  describe '#syndicate_incomplete_registrations' do

    current_user_syndicate = UseridDetail.where(userid: "Jen").first
    current_syndicate = current_user_syndicate.syndicate

    it "is a Array" do
      expect(subject.syndicate_incomplete_registrations(current_user_syndicate, current_syndicate)).to be_a Array
    end

    it "gives count as 9" do
      expect(subject.syndicate_incomplete_registrations(current_user_syndicate, current_syndicate).count).to eq 9
    end
  end
end