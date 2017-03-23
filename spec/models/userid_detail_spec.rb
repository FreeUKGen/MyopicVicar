require 'spec_helper'

describe UseridDetail do
  subject { described_class.new() }  

  describe '#list_incomplete_registrations' do
    it "is a hash" do
      expect(subject.list_incomplete_registrations).to be_a Array
    end
  end
end