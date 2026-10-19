require 'spec_helper'

RSpec.describe FreecenCoverageController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(freecen_coverage: attrs)
    controller.send(meth)
  end

  describe '#freecen_coverage_params (strong parameters)' do
    it 'permits the form fields and strips the rest' do
      result = permitted(:freecen_coverage_params, chapman_codes: ['', 'NFK'], place: 'x')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('chapman_codes')
    end
  end
end
