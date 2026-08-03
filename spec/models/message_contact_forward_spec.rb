require 'spec_helper'

RSpec.describe Message do
  describe '#record_contact_forward_delivery' do
    it 'records a sent internal forward delivery' do
      message = described_class.create!(subject: 'Forwarded contact', body: 'Please handle this', nature: 'contact', sub_nature: 'forward')
      message.record_contact_forward_delivery('sender1', ['coord1'])

      sent = message.sent_messages.first
      expect(sent.sender).to eq('sender1')
      expect(sent.recipients).to eq(['coord1'])
      expect(sent.sent_time).to be_present
    end
  end
end
