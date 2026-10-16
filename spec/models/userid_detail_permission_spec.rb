require 'spec_helper'

RSpec.describe UseridDetailPermission do
  def user(role, secondary = [], syndicate = 'Any Syndicate')
    UseridDetail.new(userid: "#{role}#{SecureRandom.hex(4)}", person_role: role, secondary_role: secondary, syndicate: syndicate)
  end

  let(:target) { user('transcriber') }

  it 'uses secondary roles as well as the person role' do
    permission = described_class.new(user('transcriber', ['system_administrator']), target, 'freereg', false)

    expect(permission.edit_person_role?).to be true
  end

  it 'gives no role, syndicate or account status field on the own Profile page' do
    permission = described_class.new(user('system_administrator'), target, 'freereg', true)

    expect(permission.update_fields).to include(:email_address_valid)
    expect(permission.update_fields).not_to include(:syndicate, :person_role, :active, :skill_level)
  end

  it 'lets only the user themselves sign the transcription agreement' do
    me = user('transcriber')

    expect(described_class.new(me, me, 'freereg', false).update_fields).to include(:new_transcription_agreement)
    expect(described_class.new(me, target, 'freereg', false).update_fields).not_to include(:new_transcription_agreement)
  end

  describe 'FreeCEN' do
    it 'lets a syndicate coordinator change syndicate and person role but not secondary roles or skill level' do
      fields = described_class.new(user('syndicate_coordinator'), target, 'freecen', false).update_fields

      expect(fields).to include(:syndicate, :person_role, :active)
      expect(fields).not_to include(:skill_level, { secondary_role: [] })
    end

    it 'lets a country coordinator of the Scotland Syndicate change syndicate only' do
      permission = described_class.new(user('country_coordinator', [], 'Scotland Syndicate'), target, 'freecen', false)

      expect(permission.edit_syndicate?).to be true
      expect(permission.edit_person_role?).to be false
    end

    it 'does not let a data manager change roles' do
      permission = described_class.new(user('data_manager'), target, 'freecen', false)

      expect(permission.edit_syndicate?).to be true
      expect(permission.edit_person_role?).to be false
    end
  end
end
