require 'spec_helper'

RSpec.describe CountiesController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(county: attrs)
    controller.send(meth)
  end

  describe '#county_create_params (strong parameters)' do
    it 'permits the form fields and strips the rest' do
      result = permitted(:county_create_params, chapman_code: 'NFK', county_description: 'Norfolk', county_coordinator: 'u', county_notes: 'n', total_records: '9', previous_county_coordinator: 'p')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('chapman_code', 'county_description', 'county_coordinator', 'county_notes')
    end
  end

  describe '#county_params (strong parameters)' do
    it 'permits the form fields and strips the rest' do
      result = permitted(:county_params, chapman_code: 'SFK', county_description: 'Suffolk', county_coordinator: 'u', previous_county_coordinator: 'p', county_notes: 'n', total_records: '9')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('county_coordinator', 'previous_county_coordinator', 'county_notes')
    end
  end
end
