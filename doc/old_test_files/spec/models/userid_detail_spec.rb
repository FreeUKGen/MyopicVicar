require 'spec_helper'

describe UseridDetail do
  subject { described_class.new() }  

  describe '#list_incomplete_registrations' do
    current_user = UseridDetail.where(person_role: "system_administrator").first
    current_syndicate = "all"

    it "is a Array" do
      expect(subject.list_incomplete_registrations(current_user,current_syndicate)).to be_a Array
    end
  end

  describe '#syndicate_incomplete_registrations' do

    current_user_syndicate = UseridDetail.where(person_role: "syndicate_coordinator").first
    current_syndicate = current_user_syndicate.syndicate

    it "is a Array" do
      expect(subject.list_incomplete_registrations(current_user_syndicate, current_syndicate)).to be_a Array
    end
  end

  describe '#syndicate_incomplete_registrations' do

    current_user_syndicate = UseridDetail.where(person_role: "country_coordinator").first
    current_syndicate = current_user_syndicate.syndicate

    it "is a Array" do
      expect(subject.list_incomplete_registrations(current_user_syndicate, current_syndicate)).to be_a Array
    end
  end

  describe '#syndicate_incomplete_registrations' do

    current_user_syndicate = UseridDetail.where(person_role: "county_coordinator").first
    current_syndicate = current_user_syndicate.syndicate

    it "is a Array" do
      expect(subject.list_incomplete_registrations(current_user_syndicate, current_syndicate)).to be_a Array
    end
  end
end