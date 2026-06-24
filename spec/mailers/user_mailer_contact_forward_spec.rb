require 'spec_helper'

RSpec.describe UserMailer, type: :mailer do
  describe '#contact_forward' do
    let(:contact) do
      Contact.new(
        identifier: '12345',
        name: 'Public Sender',
        email_address: 'public@example.org',
        body: 'Original contact body',
        contact_type: 'General Comment',
        contact_time: Time.zone.now
      )
    end

    let(:message) do
      Message.new(
        subject: 'RE: Contact subject',
        body: 'Please handle this',
        userid: 'sender1',
        sub_nature: 'forward'
      )
    end

    let(:sender) do
      double('sender', person_forename: 'Alice', person_surname: 'Sender', email_address: 'alice@example.org')
    end

    let(:recipient) do
      double('recipient', email_address: 'coord@example.org')
    end

    before do
      allow(UseridDetail).to receive(:userid).with('sender1').and_return(double(first: sender))
      allow(UseridDetail).to receive(:userid).with('coord1').and_return(double(first: recipient))
      allow(Rails.application.config).to receive(:website).and_return('https://www.freereg.org.uk')
    end

    it 'sends only to selected internal recipients' do
      mail = described_class.contact_forward(contact, message, ['coord1'], 'sender1')

      expect(mail.to).to eq(['coord@example.org'])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
      expect(mail.to).not_to include('public@example.org')
      expect(mail.subject).to include('Forwarded contact')
    end

    it 'includes the contact context and forwarding note' do
      mail = described_class.contact_forward(contact, message, ['coord1'], 'sender1')

      expect(mail.body.encoded).to include('Original contact body')
      expect(mail.body.encoded).to include('Please handle this')
      expect(mail.body.encoded).to include('12345')
    end
  end
end
