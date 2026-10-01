require 'spec_helper'

RSpec.describe Freecen1VldEntriesController, type: :controller do
  describe '#freecen1_vld_entry_params (strong parameters)' do
    before do
      controller.params = ActionController::Parameters.new(
        freecen1_vld_entry: {
          birth_county: 'NFK',
          birth_place: 'Norwich',
          notes: 'a note',
          # attacker-supplied values that are not declared fields on Freecen1VldEntry
          freecen1_vld_file_id: 'someone-elses-file-id',
          _id: 'a-different-id',
          admin: true
        }
      )
    end

    it 'permits the fields that are declared on the model' do
      permitted = controller.send(:freecen1_vld_entry_params)

      expect(permitted.permitted?).to be true
      expect(permitted[:birth_county]).to eq('NFK')
      expect(permitted[:birth_place]).to eq('Norwich')
      expect(permitted[:notes]).to eq('a note')
    end

    it 'strips parameters that are not declared fields on the model' do
      permitted = controller.send(:freecen1_vld_entry_params)

      expect(permitted.to_h.keys).not_to include('freecen1_vld_file_id', '_id', 'admin')
    end
  end

  describe 'PUT update' do
    before { allow(controller).to receive(:require_login) }

    it 'does not let submitted params reassign the entry to a different file' do
      file = Freecen1VldFile.create!(full_year: '1881')
      entry = Freecen1VldEntry.create!(
        freecen1_vld_file: file,
        birth_county: 'NFK',
        birth_place: 'Norwich',
        verbatim_birth_county: 'NFK',
        verbatim_birth_place: 'Norwich',
        notes: 'original note',
        pob_valid: false
      )
      other_file_id = BSON::ObjectId.new
      user = double('user', userid: 'transcriber1')
      allow(controller).to receive(:get_user_info_from_userid) do
        controller.instance_variable_set(:@user, user)
      end
      allow(Freecen1VldEntry).to receive(:update_linked_records_pob)

      put :update, params: {
        id: entry.id.to_s,
        commit: 'Accept',
        freecen1_vld_entry: {
          birth_county: 'NFK',
          birth_place: 'Norwich',
          notes: 'updated note',
          freecen1_vld_file_id: other_file_id.to_s
        }
      }

      entry.reload
      expect(entry.notes).to eq('updated note')
      expect(entry.freecen1_vld_file_id).to eq(file.id)
      expect(entry.freecen1_vld_file_id).not_to eq(other_file_id)
    end
  end
end
