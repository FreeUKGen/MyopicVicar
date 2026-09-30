require 'spec_helper'

RSpec.describe UseridDetailsController, type: :controller do
  describe 'profile editing by logged-in users' do
    let(:suffix) { SecureRandom.hex(4) }
    let(:syndicate) { "Syndicate #{suffix}" }
    let(:created_userids) { [] }

    def make_user(role, attributes = {})
      userid = "#{role.first(6)}#{created_userids.size}#{suffix}"
      created_userids << userid
      user = UseridDetail.new({ userid: userid, person_forename: 'Pat', person_surname: 'Smith',
                                email_address: "#{userid}@example.com", person_role: role, syndicate: syndicate,
                                skill_level: 'Learning', active: true }.merge(attributes))
      user.save!(validate: false)
      user
    end

    def act_as(user)
      allow(controller).to receive(:require_login)
      allow(controller).to receive(:get_user).and_return(user)
      session[:role] = user.person_role
    end

    let(:escalation) do
      { person_role: 'system_administrator', secondary_role: ['data_manager'], syndicate: 'Other Syndicate',
        skill_level: 'Experienced', active: 'false', disabled_reason_standard: 'Other', disabled_reason: 'forged',
        email_address_valid: 'false', reason_for_invalidating: 'forged' }
    end

    let(:transcriber) { make_user('transcriber') }
    let(:other_user) { make_user('transcriber') }
    let(:administrator) { make_user('system_administrator') }
    let(:coordinator) { make_user('syndicate_coordinator') }

    def expect_privileged_fields_unchanged(user)
      user.reload
      expect(user.person_role).to eq('transcriber')
      expect(user.secondary_role).to be_blank
      expect(user.syndicate).to eq(syndicate)
      expect(user.skill_level).to eq('Learning')
      expect(user.active).to be true
      expect(user.disabled_reason).to be_nil
      expect(user.reason_for_invalidating).to be_nil
    end

    before do
      allow_any_instance_of(UseridDetail).to receive(:write_userid_file)
      allow_any_instance_of(UseridDetail).to receive(:save_to_refinery)
      allow(UserMailer).to receive_message_chain(:send_change_of_syndicate_notification_to_sc, :deliver_now)
      allow(UserMailer).to receive_message_chain(:send_change_of_email_notification_to_sc, :deliver_now)
    end

    after { UseridDetail.where(:userid.in => created_userids).delete_all }

    describe 'PUT update' do
      def put_update(user, fields, commit = 'Update')
        put :update, params: { id: user.id, commit: commit, userid_detail: fields }
      end

      it 'lets a transcriber change their own profile but drops the fields the form hides from them' do
        act_as(transcriber)
        put_update(transcriber, escalation.merge(person_forename: 'Changed'))

        expect(transcriber.reload.person_forename).to eq('Changed')
        expect_privileged_fields_unchanged(transcriber)
      end

      it "drops the privileged fields when a transcriber submits them for another user's id" do
        act_as(transcriber)
        put_update(other_user, escalation)

        expect_privileged_fields_unchanged(other_user)
      end

      it 'ignores a role put into the session instead of held by the user' do
        act_as(transcriber)
        session[:role] = 'system_administrator'
        put_update(transcriber, escalation)

        expect_privileged_fields_unchanged(transcriber)
      end

      it "lets a system administrator change another user's roles and syndicate" do
        act_as(administrator)
        put_update(other_user, person_role: 'syndicate_coordinator', secondary_role: ['data_manager'],
                               syndicate: 'Other Syndicate')

        other_user.reload
        expect(other_user.person_role).to eq('syndicate_coordinator')
        expect(other_user.secondary_role).to eq(['data_manager'])
        expect(other_user.syndicate).to eq('Other Syndicate')
        expect(other_user.previous_syndicate).to eq(syndicate)
      end

      it 'drops role fields when a system administrator edits from their own Profile page' do
        act_as(administrator)
        session[:my_own] = true
        put_update(administrator, person_role: 'transcriber')

        expect(administrator.reload.person_role).to eq('system_administrator')
      end

      it "lets a syndicate coordinator change another user's account status but not their role (FreeREG)" do
        act_as(coordinator)
        put_update(other_user, skill_level: 'Experienced', active: 'false', disabled_reason_standard: 'Other',
                               person_role: 'system_administrator', secondary_role: ['data_manager'])

        other_user.reload
        expect(other_user.skill_level).to eq('Experienced')
        expect(other_user.active).to be false
        expect(other_user.disabled_reason_standard).to eq('Other')
        expect(other_user.person_role).to eq('transcriber')
        expect(other_user.secondary_role).to be_blank
      end

      it 'lets a coordinator disable another user' do
        act_as(coordinator)
        put_update(other_user, { disabled_reason_standard: 'Other', disabled_reason: 'left' }, 'Disable')

        other_user.reload
        expect(other_user.active).to be false
        expect(other_user.disabled_reason).to eq('left')
        expect(other_user.disabled_date).to be_present
      end
    end

    describe 'GET edit' do
      render_views
      # the application layout needs compiled assets, which the test environment lacks
      before { allow(controller).to receive(:_layout).and_return(false) }

      it 'shows a transcriber their own profile without the privileged fields' do
        act_as(transcriber)
        get :edit, params: { id: transcriber.id }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('userid_detail[person_forename]')
        expect(response.body).not_to include('userid_detail[active]')
        expect(response.body).not_to include('userid_detail[person_role]')
        expect(response.body).not_to include('userid_detail[syndicate]')
      end

      it 'shows a coordinator the account status fields but not the role fields' do
        act_as(coordinator)
        get :edit, params: { id: other_user.id }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('userid_detail[active]')
        expect(response.body).not_to include('userid_detail[person_role]')
      end
    end
  end

  describe 'POST create by an anonymous user (public registration)' do
    let(:uid) { "reg#{SecureRandom.hex(4)}" }
    let(:honeypot) { 'agreement_123' }
    let(:attacker_fields) do
      { person_role: 'system_administrator', secondary_role: ['data_manager'], skill_level: 'Experienced',
        email_address_valid: 'false', reason_for_invalidating: 'forged', disabled_reason: 'forged' }
    end

    def post_registration(commit, fields = {})
      post :create, params: {
        commit: commit, __TIME: (Time.now - 60).to_s, honeypot => '',
        userid_detail: { userid: uid, person_forename: 'Pat', person_surname: 'Smith',
                         email_address: "#{uid}@example.com", syndicate: 'Any Syndicate' }.merge(fields)
      }
    end

    before do
      session[:honeypot] = honeypot
      # the test environment lacks the digest pepper and a mailer host; neither is under test here
      allow(Devise::Encryptable::Encryptors::Freereg).to receive(:digest).and_return('digest')
      allow_any_instance_of(User).to receive(:send_reset_password_instructions)
      allow_any_instance_of(UseridDetail).to receive(:write_userid_file)
      allow_any_instance_of(UseridDetail).to receive(:finish_creation_setup)
      allow_any_instance_of(UseridDetail).to receive(:finish_researcher_creation_setup)
      allow_any_instance_of(UseridDetail).to receive(:finish_technical_creation_setup)
    end

    after { UseridDetail.where(userid: uid).delete_all }

    it 'rejects a commit that is not one of the public registration buttons, creating nothing' do
      post_registration('Update', attacker_fields)

      expect(response).to have_http_status(:not_found)
      expect(UseridDetail.where(userid: uid).exists?).to be false
    end

    it 'rejects a request with no commit' do
      post_registration(nil, attacker_fields)

      expect(response).to have_http_status(:not_found)
      expect(UseridDetail.where(userid: uid).exists?).to be false
    end

    it 'ignores role and account-status fields on a transcriber registration' do
      post_registration('Register as Transcriber',
                        attacker_fields.merge(new_transcription_agreement: '1', code_of_conduct: '1',
                                              volunteer_induction_handbook: '1', volunteer_policy: '1'))

      user = UseridDetail.where(userid: uid).first
      expect(user).to be_present
      expect(user.person_role).to eq('transcriber')
      expect(user.secondary_role).to be_blank
      expect(user.skill_level).not_to eq('Experienced')
      expect(user.reason_for_invalidating).not_to eq('forged')
      expect(user.disabled_reason).not_to eq('forged')
    end

    it 'ignores role fields on a researcher registration' do
      post_registration('Register Researcher', attacker_fields.merge(transcription_agreement: 'true'))

      user = UseridDetail.where(userid: uid).first
      expect(user).to be_present
      expect(user.person_role).to eq('researcher')
      expect(user.secondary_role).to be_blank
    end

    it 'enforces the code of conduct / policy / handbook check boxes on transcriber registration' do
      post_registration('Register as Transcriber',
                        new_transcription_agreement: '1', code_of_conduct: '0',
                        volunteer_induction_handbook: '1', volunteer_policy: '1')

      expect(UseridDetail.where(userid: uid).exists?).to be false
    end
  end

  describe '#registration_params (strong parameters)' do
    it 'permits only the public registration form fields' do
      controller.params = ActionController::Parameters.new(
        userid_detail: { userid: 'u', person_forename: 'P', syndicate: 'S', skill_notes: 'n', code_of_conduct: '1',
                         person_role: 'system_administrator', secondary_role: ['data_manager'], active: 'true',
                         skill_level: 'x', email_address_valid: 'true', disabled_date: 'd' }
      )

      permitted = controller.send(:registration_params)

      expect(permitted).to be_permitted
      expect(permitted.to_h.keys).to contain_exactly('userid', 'person_forename', 'syndicate', 'skill_notes',
                                                     'code_of_conduct')
    end
  end
end
