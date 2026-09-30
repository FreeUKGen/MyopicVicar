require 'spec_helper'

RSpec.describe SearchQueriesController, type: :controller do
  describe '#permitted_model_params (via search_params)' do
    def permitted(attrs)
      controller.params = ActionController::Parameters.new(search_query: attrs)
      controller.send(:search_params)
    end

    it 'permits declared scalar and array fields' do
      result = permitted(last_name: 'Smith', start_year: '1800', chapman_codes: %w[NFK SFK])
      expect(result).to be_permitted
      expect(result[:last_name]).to eq('Smith')
      expect(result[:chapman_codes]).to eq(%w[NFK SFK])
    end

    it 'strips undeclared keys and _id/_type' do
      result = permitted(last_name: 'Smith', _id: 'x', _type: 'y', admin: 'true')
      expect(result.to_h.keys).to eq(['last_name'])
    end

    it 'strips nested hashes given for scalar fields' do
      result = permitted(last_name: { '$ne' => '' })
      expect(result.to_h.keys).not_to include('last_name')
    end

    it 'strips scalars given for array fields' do
      result = permitted(chapman_codes: 'NFK')
      expect(result.to_h.keys).not_to include('chapman_codes')
    end
  end
end
