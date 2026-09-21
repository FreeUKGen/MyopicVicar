require 'spec_helper'

RSpec.describe FreecenCsvEntriesController, type: :controller do
  describe '#freecen_csv_entry_params (strong parameters)' do
    before do
      controller.params = ActionController::Parameters.new(
        freecen_csv_entry: {
          surname: 'Smith',
          forenames: 'John',
          notes: 'a note',
          # attacker-supplied values that are not declared fields on FreecenCsvEntry
          freecen_csv_file_id: 'someone-elses-file-id',
          _id: 'a-different-id',
          admin: true
        }
      )
    end

    it 'permits the fields that are declared on the model' do
      permitted = controller.send(:freecen_csv_entry_params)

      expect(permitted.permitted?).to be true
      expect(permitted[:surname]).to eq('Smith')
      expect(permitted[:forenames]).to eq('John')
      expect(permitted[:notes]).to eq('a note')
    end

    it 'strips parameters that are not declared fields on the model' do
      permitted = controller.send(:freecen_csv_entry_params)

      expect(permitted.to_h.keys).not_to include('freecen_csv_file_id', '_id', 'admin')
    end
  end

  describe 'PUT update' do
    before { allow(controller).to receive(:require_login) }

    it 'does not let submitted params reassign the entry to a different file' do
      piece = Freecen2Piece.create!(name: 'Piece 1', chapman_code: 'NFK', number: 1, year: '1881', admin_county: 'NFK')
      file = FreecenCsvFile.create!(freecen2_piece_id: piece.id, userid: 'transcriber1', file_name: 'test_file.csv')
      entry = FreecenCsvEntry.create!(
        freecen_csv_file: file,
        birth_county: 'NFK',
        birth_place: 'Norwich',
        verbatim_birth_place: 'Norwich',
        notes: 'original note',
        record_valid: 'true',
        warning_messages: '',
        error_messages: ''
      )
      other_file_id = BSON::ObjectId.new

      put :update, params: {
        id: entry.id.to_s,
        commit: 'Save',
        freecen_csv_entry: {
          birth_county: 'NFK',
          birth_place: 'Norwich',
          verbatim_birth_place: 'Norwich',
          notes: 'updated note',
          record_valid: 'true',
          freecen_csv_file_id: other_file_id.to_s
        }
      }

      entry.reload
      expect(entry.notes).to eq('updated note')
      expect(entry.freecen_csv_file_id).to eq(file.id)
      expect(entry.freecen_csv_file_id).not_to eq(other_file_id)
    end
  end
end
