require 'spec_helper'

RSpec.describe Freecen2PiecesController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(freecen2_piece: attrs)
    controller.send(meth)
  end

  describe '#freecen2_piece_params (strong parameters)' do
    it 'permits the edit form fields and strips status/count/location fields' do
      result = permitted(:freecen2_piece_params,
                         name: 'P', number: 'RG11/1', admin_county: 'NFK', remarks_coord: 'r', film_number: 'f',
                         status: 'Online', num_individuals: '99', chapman_code: 'SFK', year: '1891',
                         freecen2_district_id: 'd', status_date: '2020-01-01')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('name', 'number', 'admin_county', 'remarks_coord', 'film_number')
    end
  end
end
