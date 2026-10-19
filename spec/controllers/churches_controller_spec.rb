require 'spec_helper'

RSpec.describe ChurchesController, type: :controller do
  describe '#church_params (strong parameters)' do
    def permitted(attrs)
      controller.params = ActionController::Parameters.new(church: attrs)
      controller.send(:church_params)
    end

    it 'permits form fields and nested alternate names, strips system fields' do
      result = permitted(church_name: 'St Mary', denomination: 'Anglican', place_name: 'x', records: '9',
                         alternatechurchnames_attributes: { '0' => { alternate_name: 'Alt', _destroy: '0', id: 'a', extra: 'z' } })
      expect(result).to be_permitted
      expect(result[:church_name]).to eq('St Mary')
      expect(result.to_h.keys).not_to include('place_name', 'records')
      nested = result[:alternatechurchnames_attributes]['0']
      expect(nested.keys).to contain_exactly('alternate_name', '_destroy', 'id')
    end
  end
end
