require 'spec_helper'

RSpec.describe UseridDetail do
  describe '.internal_contact_recipient_options' do
    let(:valid_user) do
      described_class.new(
        userid: 'coord1',
        userid_lower_case: 'coord1',
        person_forename: 'Ann',
        person_surname: 'Coordinator',
        person_role: 'contacts_coordinator',
        secondary_role: [],
        active: true,
        email_address_valid: true
      )
    end

    let(:inactive_user) do
      described_class.new(
        userid: 'inactive1',
        userid_lower_case: 'inactive1',
        person_forename: 'Ian',
        person_surname: 'Inactive',
        person_role: 'contacts_coordinator',
        secondary_role: [],
        active: false,
        email_address_valid: true
      )
    end

    let(:invalid_email_user) do
      described_class.new(
        userid: 'invalid1',
        userid_lower_case: 'invalid1',
        person_forename: 'Eve',
        person_surname: 'Invalid',
        person_role: 'contacts_coordinator',
        secondary_role: [],
        active: true,
        email_address_valid: false
      )
    end

    it 'returns named active internal recipients with userid values' do
      relation = double('recipient relation')
      allow(described_class).to receive(:active).with(true).and_return(relation)
      allow(relation).to receive(:email_address_valid).and_return(relation)
      allow(relation).to receive(:where).and_return(relation)
      allow(relation).to receive(:any_of).and_return(relation)
      allow(relation).to receive(:order_by).and_return([valid_user])

      expect(described_class.internal_contact_recipient_options).to eq([
        ['Ann Coordinator (coord1) — contacts_coordinator', 'coord1']
      ])
    end

    it 'queries only active users with valid email addresses' do
      relation = double('recipient relation')
      allow(described_class).to receive(:active).with(true).and_return(relation)
      allow(relation).to receive(:email_address_valid).and_return(relation)
      allow(relation).to receive(:where).and_return(relation)
      allow(relation).to receive(:any_of).and_return(relation)
      allow(relation).to receive(:order_by).and_return([valid_user])

      described_class.internal_contact_recipient_options

      expect(described_class).to have_received(:active).with(true)
      expect(relation).to have_received(:email_address_valid)
      expect(relation).to have_received(:where).with(:email_address.nin => [nil, ''])
      expect(relation).to have_received(:any_of)
    end
  end
end
