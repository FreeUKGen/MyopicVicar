require 'spec_helper'

RSpec.describe ReminderToDonateController, type: :controller do
  describe '#reminder_to_donate_params (strong parameters)' do
    it 'permits name/email and strips everything else' do
      controller.params = ActionController::Parameters.new(
        reminder_to_donate: {
          name: 'Jane Doe',
          email: 'jane@example.com',
          # not submitted by the reminder_to_donate form
          _id: 'a-different-id',
          admin: true
        }
      )

      permitted = controller.send(:reminder_to_donate_params)

      expect(permitted.permitted?).to be true
      expect(permitted[:name]).to eq('Jane Doe')
      expect(permitted[:email]).to eq('jane@example.com')
      expect(permitted.to_h.keys).not_to include('_id', 'admin')
    end
  end
end
