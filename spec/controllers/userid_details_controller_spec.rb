require 'spec_helper'

RSpec.describe UseridDetailsController, type: :controller do
  describe '#userid_details_params (strong parameters)' do
    before do
      controller.params = ActionController::Parameters.new(
        userid_detail: {
          person_forename: 'Jane',
          person_surname: 'Doe',
          email_address: 'jane@example.com',
          person_role: 'system_administrator',
          active: true,
          secondary_role: ['volunteer_coordinator'],
          # attacker-supplied values that are not part of the userid_details forms
          digest: 'attacker-set-password-digest',
          syndicate_groups: ['NFK'],
          county_groups: ['NFK'],
          country_groups: ['England'],
          userid_messages: ['forged message'],
          userid_feedback_replies: { 'x' => 'y' },
          email_address_validity_change_message: ['forged'],
          favorite_actions: ['forged'],
          sign_up_date: '2000-01-01',
          number_of_files: 999,
          number_of_records: 999,
          technical_agreement: true,
          research_agreement: true,
          _id: 'a-different-id'
        }
      )
    end

    it 'permits the fields the userid_details forms submit' do
      permitted = controller.send(:userid_details_params)

      expect(permitted.permitted?).to be true
      expect(permitted[:person_forename]).to eq('Jane')
      expect(permitted[:email_address]).to eq('jane@example.com')
      expect(permitted[:person_role]).to eq('system_administrator')
      expect(permitted[:active]).to eq(true)
      expect(permitted[:secondary_role]).to eq(['volunteer_coordinator'])
    end

    it 'strips fields that are not part of the userid_details forms' do
      permitted = controller.send(:userid_details_params)

      expect(permitted.to_h.keys).not_to include(
        'digest', 'syndicate_groups', 'county_groups', 'country_groups',
        'userid_messages', 'userid_feedback_replies',
        'email_address_validity_change_message', 'favorite_actions',
        'sign_up_date', 'number_of_files', 'number_of_records',
        'technical_agreement', 'research_agreement', '_id'
      )
    end
  end
end
