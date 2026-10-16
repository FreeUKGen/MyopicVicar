require 'spec_helper'

RSpec.describe Freereg1CsvEntriesController, type: :controller do
  describe '#freereg1_csv_entry_params (strong parameters)' do
    it 'permits declared scalar fields and strips fields that are not declared on the model' do
      controller.params = ActionController::Parameters.new(
        freereg1_csv_entry: {
          person_forename: 'Jane',
          person_surname: 'Doe',
          notes: 'a note',
          # attacker-supplied values that are not declared fields on Freereg1CsvEntry
          freereg1_csv_file_id: 'someone-elses-file-id',
          _id: 'a-different-id',
          admin: true
        }
      )

      permitted = controller.send(:freereg1_csv_entry_params)

      expect(permitted.permitted?).to be true
      expect(permitted[:person_forename]).to eq('Jane')
      expect(permitted[:person_surname]).to eq('Doe')
      expect(permitted[:notes]).to eq('a note')
      expect(permitted.to_h.keys).not_to include('freereg1_csv_file_id', '_id', 'admin')
    end

    it 'permits only the embargo_records_attributes fields the edit_embargo form submits' do
      controller.params = ActionController::Parameters.new(
        freereg1_csv_entry: {
          embargo_records_attributes: {
            '0' => {
              embargoed: 'true',
              why: 'sensitive',
              release_date: '2030',
              when: '2024-01-01',
              who: 'transcriber1',
              # rule_applied/rule_date/release_year are set only by internal embargo-rule
              # logic; a user submitting them here would be forging or manipulating an
              # embargo's computed release year, so they must be stripped.
              rule_applied: 'attacker-set-rule',
              rule_date: '2000-01-01',
              release_year: '1900'
            }
          }
        }
      )

      permitted = controller.send(:freereg1_csv_entry_params)
      record = permitted[:embargo_records_attributes]['0']

      expect(record[:embargoed]).to eq('true')
      expect(record[:why]).to eq('sensitive')
      expect(record[:release_date]).to eq('2030')
      expect(record.to_h.keys).not_to include('rule_applied', 'rule_date', 'release_year')
    end

    it 'permits only the declared multiple_witnesses_attributes fields' do
      controller.params = ActionController::Parameters.new(
        freereg1_csv_entry: {
          multiple_witnesses_attributes: {
            '0' => {
              id: 'witness-id',
              witness_forename: 'Alice',
              witness_surname: 'Brown',
              _destroy: 'false',
              # not a declared field on MultipleWitness
              admin: true
            }
          }
        }
      )

      permitted = controller.send(:freereg1_csv_entry_params)
      witness = permitted[:multiple_witnesses_attributes]['0']

      expect(witness[:witness_forename]).to eq('Alice')
      expect(witness[:witness_surname]).to eq('Brown')
      expect(witness[:_destroy]).to eq('false')
      expect(witness.to_h.keys).not_to include('admin')
    end

    it 'strips nested attributes for associations that are not declared as accepting them' do
      controller.params = ActionController::Parameters.new(
        freereg1_csv_entry: {
          notes: 'a note',
          search_record_attributes: { some_field: 'attacker-injected' }
        }
      )

      permitted = controller.send(:freereg1_csv_entry_params)

      expect(permitted.to_h.keys).not_to include('search_record_attributes')
    end
  end
end
