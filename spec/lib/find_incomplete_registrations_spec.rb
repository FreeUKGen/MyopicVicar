require 'find_incomplete_registrations'
require 'spec_helper'

describe FindIncompleteRegistrations do 
	subject { described_class.new() }

	describe '#initialize' do
		it "initializes the user_details with UseridDetail" do
			expect(described_class.new().user_details).to eq UseridDetail
		end

		it "initialzes the incompleted_registration_ids with an empty array" do
			expect(described_class.new().incompleted_registration_ids).to eq []
		end
	end

	describe '#system_administrator?' do
		let(:technical_user) { UseridDetail.find('58ca6480d7b56b19250a2e8d') }
		let(:system_administrator) { UseridDetail.find('5462b404e937907d700000b1') }

		it 'returns false when user_id is nil' do
			expect(subject.system_administrator? nil).to eq false
		end

		it 'returns false when the user is not a system_administrator' do
			expect(subject.system_administrator? technical_user).to eq false
		end

		it 'returns true when the user is a system_administrator' do
			expect(subject.system_administrator? system_administrator).to eq true
		end
	end

	describe '#list_incomplete_registrations' do
  	let!(:incompleted_registration_users) { ['User1', 'User2'] }

		it "returns the list of userids of incomplete registrations" do
			allow(subject).to receive(:list_incomplete_registrations).and_return(incompleted_registration_users)
			expect(subject.list_incomplete_registrations).to eq ['User1', 'User2']
		end
	end

end