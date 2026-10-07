require 'spec_helper'

RSpec.describe GapReasonsController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(gap_reason: attrs)
    controller.send(meth)
  end

  describe '#gap_reason_params (strong parameters)' do
    it 'permits the form fields and strips the rest' do
      result = permitted(:gap_reason_params, reason: 'r', notes: 'n', _id: 'x')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('reason', 'notes')
    end
  end
end
