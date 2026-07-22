require 'spec_helper'

RSpec.describe 'contact forward views', type: :view do
  describe 'contacts/_show_nav.html.erb' do
    it 'renders Forward alongside contact actions' do
      contact = double('contact', id: 'contact1', keep: nil)
      assign(:contact, contact)
      allow(view).to receive(:show_contact_add_comment_link).and_return('')
      allow(view).to receive(:do_we_show_archive_contact_action?).and_return(true)
      allow(view).to receive(:do_we_show_restore_contact_action?).and_return(false)
      allow(view).to receive(:do_we_show_github_create_contact_action?).and_return(false)

      render partial: 'contacts/show_nav'

      expect(rendered).to include('Create Reply')
      expect(rendered).to include('Forward')
      expect(rendered).to include('Archive')
      expect(rendered).to include('/contacts/contact1/forward')
    end
  end

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
      assign_forward_contact(forward_contact)

      render template: 'contacts/forward_contact'

      expect(rendered).to include('Ann Coordinator (coord1) — contacts_coordinator')
      expect(rendered).to include('value="coord1"')
    end

    it 'does not show an attachment notice when there are no attachments' do
      contact = forward_contact
      allow(contact).to receive(:attachment_file_paths).and_return([])
      assign_forward_contact(contact)

      render template: 'contacts/forward_contact'

      expect(rendered).not_to include('Attachments will be forwarded')
      expect(rendered).not_to include('This contact has')
    end

    it 'shows the filename when one attachment will be forwarded' do
      contact = forward_contact
      allow(contact).to receive(:attachment_file_paths).and_return(['/tmp/contact evidence.png'])
      assign_forward_contact(contact)

      render template: 'contacts/forward_contact'

      expect(rendered).to include('Attachments will be forwarded with this contact.')
      expect(rendered).to include('This contact has 1 attachment')
      expect(rendered).to include('contact evidence.png')
    end

    it 'shows the count and filenames when multiple attachments will be forwarded' do
      contact = forward_contact
      allow(contact).to receive(:attachment_file_paths).and_return(['/tmp/first.png', '/tmp/second.pdf'])
      assign_forward_contact(contact)

      render template: 'contacts/forward_contact'

      expect(rendered).to include('This contact has 2 attachments')
      expect(rendered).to include('first.png')
      expect(rendered).to include('second.pdf')
    end

    it 'does not display a missing attachment path as an attachment' do
      contact = forward_contact(screenshot_location: 'uploads/contact/screenshots/contact1/missing.png')
      assign_forward_contact(contact)

      render template: 'contacts/forward_contact'

      expect(rendered).not_to include('Attachments will be forwarded')
      expect(rendered).not_to include('missing.png')
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

  def forward_contact(attributes = {})
    Contact.new({
      identifier: '12345',
      name: 'Public Sender',
      email_address: 'public@example.org',
      body: 'Original contact body',
      contact_type: 'General Comment',
      contact_time: Time.zone.now
    }.merge(attributes))
  end

  def assign_forward_contact(contact)
    assign(:respond_to_contact, contact)
    assign(:message, Message.new(subject: 'RE: Contact subject'))
    assign(:recipient_options, [['Ann Coordinator (coord1) — contacts_coordinator', 'coord1']])
  end
end
