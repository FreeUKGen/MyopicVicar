require 'spec_helper'

RSpec.describe AliasPlaceChurchesController, type: :controller do
  before { allow(controller).to receive(:require_login) }

  describe 'POST create with the Search button' do
    it 'redirects to the county listing with only the keys the listing reads' do
      post :create, params: { commit: 'Search', alias_place_church: { chapman_code: 'NFK', place_name: 'x' } }

      expect(response).to redirect_to(
        alias_place_churches_path(commit: 'Search', alias_place_church: { chapman_code: 'NFK' })
      )
    end
  end
end
