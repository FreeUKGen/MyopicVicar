require 'spec_helper'

RSpec.describe Freecen2PlaceSourcesController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(freecen2_place_source: attrs)
    controller.send(meth)
  end

  describe '#freecen2_place_source_params (strong parameters)' do
    it 'permits only source' do
      result = permitted(:freecen2_place_source_params, source: 'Genuki', _id: 'x', other: 'y')
      expect(result).to be_permitted
      expect(result.to_h).to eq('source' => 'Genuki')
    end
  end
end
