require 'spec_helper'

RSpec.describe Freecen2PlacesController, type: :controller do
  describe '#freecen2_place_params (strong parameters)' do
    def permitted(attrs)
      controller.params = ActionController::Parameters.new(freecen2_place: attrs)
      controller.send(:freecen2_place_params)
    end

    it 'permits form fields, reason array and nested alternate names' do
      result = permitted(place_name: 'p', county: 'Norfolk', editor: 'ed', reason_for_change: %w[a b],
                         disabled: 'true', data_present: true, transcribers: { a: 1 },
                         alternate_freecen2_place_names_attributes: { '0' => { alternate_name: 'Alt', standard_alternate_name: 'z', _destroy: '1' } })
      expect(result).to be_permitted
      expect(result[:reason_for_change]).to eq(%w[a b])
      expect(result.to_h.keys).not_to include('disabled', 'data_present', 'transcribers')
      expect(result[:alternate_freecen2_place_names_attributes]['0'].keys).to contain_exactly('alternate_name', '_destroy')
    end
  end
end
