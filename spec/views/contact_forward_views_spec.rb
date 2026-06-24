require 'spec_helper'

RSpec.describe 'contact forward views', type: :view do
  describe 'contacts/_list_contacts.html.erb' do
    it 'renders Forward beside Reply' do
      contact = double(
        'contact',
        id: 'contact1',
        name: 'Public Sender',
        email_address: 'public@example.org',
        contact_type: 'General Comment',
        county: nil,
        contact_time: Time.zone.now,
        keep: nil,
        identifier: '12345',
        has_replies?: false,
        is_archived?: false
      )

      render partial: 'contacts/list_contacts', locals: { contacts: [contact], text: 'active' }

      expect(rendered).to include('Reply')
      expect(rendered).to include('Forward')
    end
  end

  describe 'contacts/forward_contact.html.erb' do
    it 'shows named recipients while using userid values' do
      assign(:respond_to_contact, Contact.new(identifier: '12345', name: 'Public Sender', email_address: 'public@example.org', body: 'Original contact body', contact_type: 'General Comment', contact_time: Time.zone.now))
      assign(:message, Message.new(subject: 'RE: Contact subject'))
      assign(:recipient_options, [['Ann Coordinator (coord1) — contacts_coordinator', 'coord1']])

      render template: 'contacts/forward_contact'

      expect(rendered).to include('Ann Coordinator (coord1) — contacts_coordinator')
      expect(rendered).to include('value="coord1"')
    end
  end

  describe 'messages/_form_for_contact.html.erb' do
    it 'renders named CC options with userid values' do
      params[:source_contact_id] = 'contact1'
      assign(:message, Message.new)
      assign(:recipient_options, [['Ann Coordinator (coord1) — contacts_coordinator', 'coord1']])

      render partial: 'messages/form_for_contact'

      expect(rendered).to include('Ann Coordinator (coord1) — contacts_coordinator')
      expect(rendered).to include('value="coord1"')
    end
  end
end
