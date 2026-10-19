require 'spec_helper'

RSpec.describe Freecen2CivilParishesController, type: :controller do
  describe '#freecen2_civil_parish_params (strong parameters)' do
    def permitted(attrs)
      controller.params = ActionController::Parameters.new(freecen2_civil_parish: attrs)
      controller.send(:freecen2_civil_parish_params)
    end

    it 'permits edit fields and the three nested associations only' do
      result = permitted(name: 'n', note: 'x', reason_changed: 'r', chapman_code: 'NFK', year: '1881',
                         freecen2_hamlets_attributes: { '0' => { name: 'h', note: 'n', prenote: 'no', _destroy: '0' } },
                         freecen2_townships_attributes: { '0' => { name: 't' } },
                         freecen2_wards_attributes: { '0' => { name: 'w' } })
      expect(result).to be_permitted
      expect(result.to_h.keys).not_to include('chapman_code', 'year')
      expect(result[:freecen2_hamlets_attributes]['0'].keys).to contain_exactly('name', 'note', '_destroy')
      expect(result[:freecen2_townships_attributes]['0'][:name]).to eq('t')
      expect(result[:freecen2_wards_attributes]['0'][:name]).to eq('w')
    end
  end
end
