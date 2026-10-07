require 'spec_helper'

RSpec.describe ContactsController, type: :controller do
  describe '#contact_params (strong parameters)' do
    it 'permits the fields the contact forms submit' do
      controller.params = ActionController::Parameters.new(
        contact: {
          name: 'Jane Doe',
          email_address: 'jane@example.com',
          body: 'Please help',
          contact_type: 'Data Question',
          contact_time: '2024-01-01T00:00:00Z',
          record_id: 'rec1',
          entry_id: 'entry1',
          line_id: 'line1',
          county: 'NFK',
          # attacker-supplied values that are not submitted by any contact form
          archived: true,
          keep: true,
          github_issue_url: 'http://evil.example.com',
          contact_action_sent_to_userid: 'admin',
          copies_of_contact_action_sent_to_userids: ['admin'],
          routed_syndicate_code: 'NFK',
          identifier: 'attacker-set-identifier',
          _id: 'a-different-id'
        }
      )

      permitted = controller.send(:contact_params)

      expect(permitted.permitted?).to be true
      expect(permitted[:name]).to eq('Jane Doe')
      expect(permitted[:body]).to eq('Please help')
      expect(permitted.to_h.keys).not_to include(
        'archived', 'keep', 'github_issue_url', 'contact_action_sent_to_userid',
        'copies_of_contact_action_sent_to_userids', 'routed_syndicate_code',
        'identifier', '_id'
      )
    end
  end

  describe 'POST create' do
    before { Rails.cache.clear }

    it 'does not let submitted params set internal-only fields like archived/keep/github fields' do
      allow_any_instance_of(Contact).to receive(:communicate_initial_contact)

      post :create, params: {
        contact: {
          name: 'Jane Doe',
          email_address: 'jane@example.com',
          body: 'Please help with my record',
          contact_type: 'Data Question',
          contact_time: 10.seconds.ago.to_s,
          archived: true,
          keep: true,
          github_issue_url: 'http://evil.example.com',
          contact_action_sent_to_userid: 'admin'
        }
      }

      contact = Contact.last
      expect(contact.name).to eq('Jane Doe')
      expect(contact.archived).to eq(false)
      expect(contact.keep).to eq(false)
      expect(contact.github_issue_url).to be_nil
      expect(contact.contact_action_sent_to_userid).to be_nil
    end
  end
end
