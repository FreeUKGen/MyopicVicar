require 'spec_helper'

RSpec.describe PlacesController, type: :controller do
  describe '#place_params (strong parameters)' do
    def permitted(attrs)
      controller.params = ActionController::Parameters.new(place: attrs)
      controller.send(:place_params)
    end

    it 'permits form fields and nested alternate place names, strips system fields' do
      result = permitted(place_name: 'p', county: 'Norfolk', reason_for_change: 'r', disabled: 'true',
                         ucf_list: { a: 1 }, alternateplacenames_attributes: { '0' => { alternate_name: 'A', _destroy: '0' } })
      expect(result).to be_permitted
      expect(result.to_h.keys).not_to include('disabled', 'ucf_list')
      expect(result[:alternateplacenames_attributes]['0'].keys).to contain_exactly('alternate_name', '_destroy')
    end
  end
end
