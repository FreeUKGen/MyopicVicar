require 'incomplete_registration'
require 'spec_helper'

describe IncompleteRegistration do
  subject { described_class.new() }

  describe '#initialize' do
    context 'when initialized' do
      specify { expect(subject.user_details).to eq UseridDetail }

      specify { expect(subject.incompleted_registration_users).to eq [] }
    end
  end

  describe '#list_incomplete_registrations' do
    it "is a hash" do
      expect(subject.list_users).to be_a Array
    end
  end
end