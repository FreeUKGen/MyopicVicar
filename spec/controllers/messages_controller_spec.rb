require 'spec_helper'

RSpec.describe MessagesController, type: :controller do
  describe '#message_params (strong parameters)' do
    def permitted(attrs)
      controller.params = ActionController::Parameters.new(message: attrs)
      controller.send(:message_params)
    end

    it 'permits the message form fields and copies_to_userids array' do
      result = permitted(subject: 's', body: 'b', userid: 'u', copies_to_userids: %w[a b],
                         nature: 'forged', archived: 'true', recipients: ['x'],
                         sent_messages_attributes: { '0' => { sender: 'x' } })
      expect(result).to be_permitted
      expect(result[:copies_to_userids]).to eq(%w[a b])
      expect(result.to_h.keys).not_to include('nature', 'archived', 'recipients', 'sent_messages_attributes')
    end
  end
end
