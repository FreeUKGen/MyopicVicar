require 'spec_helper'

RSpec.describe PlaceEditReasonsController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(place_edit_reason: attrs)
    controller.send(meth)
  end

  describe '#place_edit_reason_params (strong parameters)' do
    it 'permits the form fields and strips the rest' do
      result = permitted(:place_edit_reason_params, reason: 'r', _id: 'x')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('reason')
    end
  end
end
