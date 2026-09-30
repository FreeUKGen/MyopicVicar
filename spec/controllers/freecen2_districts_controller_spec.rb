require 'spec_helper'

RSpec.describe Freecen2DistrictsController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(freecen2_district: attrs)
    controller.send(meth)
  end

  describe '#freecen2_district_create_params (strong parameters)' do
    it 'permits the new-district form fields, including chapman_code and year' do
      result = permitted(:freecen2_district_create_params,
                         name: 'D', freecen2_place_id: 'p', chapman_code: 'NFK', year: '1881', type: 'x',
                         county_id: 'c', standard_name: 's', vld_files: ['a'])
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('name', 'freecen2_place_id', 'chapman_code', 'year', 'type')
    end
  end

  describe '#freecen2_district_params (strong parameters, edit form)' do
    it 'strips chapman_code and year, which are disabled on the edit form' do
      result = permitted(:freecen2_district_params,
                         name: 'D', notes: 'n', code: '1', chapman_code: 'SFK', year: '1891', county_id: 'c')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('name', 'notes', 'code')
    end
  end
end
