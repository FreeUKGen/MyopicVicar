require 'spec_helper'

RSpec.describe DonateCtaFeedbackController, type: :controller do
  describe '#feedback_params (strong parameters)' do
    it 'permits name/email_address/body and strips everything else' do
      controller.params = ActionController::Parameters.new(
        feedback: {
          name: 'Jane Doe',
          email_address: 'jane@example.com',
          body: 'Thanks for the reminder',
          # not submitted by the donate_cta_feedback form
          identifier: 'attacker-set-identifier',
          _id: 'a-different-id'
        }
      )

      permitted = controller.send(:feedback_params)

      expect(permitted.permitted?).to be true
      expect(permitted[:name]).to eq('Jane Doe')
      expect(permitted[:email_address]).to eq('jane@example.com')
      expect(permitted[:body]).to eq('Thanks for the reminder')
      expect(permitted.to_h.keys).not_to include('identifier', '_id')
    end
  end
end
