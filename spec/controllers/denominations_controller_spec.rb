require 'spec_helper'

RSpec.describe DenominationsController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(denomination: attrs)
    controller.send(meth)
  end

  describe '#denomination_params (strong parameters)' do
    it 'permits the form fields and strips the rest' do
      result = permitted(:denomination_params, denomination: 'Anglican', notes: 'n', _id: 'x')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('denomination', 'notes')
    end
  end
end
