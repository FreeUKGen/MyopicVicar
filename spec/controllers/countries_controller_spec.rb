require 'spec_helper'

RSpec.describe CountriesController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(country: attrs)
    controller.send(meth)
  end

  describe '#country_create_params (strong parameters)' do
    it 'permits the form fields and strips the rest' do
      result = permitted(:country_create_params, country_code: 'ENG', country_description: 'England', country_coordinator: 'u', country_notes: 'n', counties_included: ['NFK'], previous_country_coordinator: 'p')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('country_code', 'country_description', 'country_coordinator', 'country_notes')
    end
  end

  describe '#country_params (strong parameters)' do
    it 'permits the form fields and strips the rest' do
      result = permitted(:country_params, country_code: 'XXX', country_description: 'England', country_coordinator: 'u', previous_country_coordinator: 'p', country_notes: 'n', counties_included: ['NFK'])
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('country_description', 'country_coordinator', 'previous_country_coordinator', 'country_notes')
    end
  end
end
