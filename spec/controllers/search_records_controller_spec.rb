require 'spec_helper'

RSpec.describe SearchRecordsController do
  describe 'routing', type: :routing do
    let(:object_id) { '507f1f77bcf86cd799439011' }

    it 'routes GET /search_records/:id (a Mongo ObjectId) to #show' do
      expect(get: "/search_records/#{object_id}").to route_to('search_records#show', id: object_id)
    end

    it 'no longer routes GET /search_records to #index' do
      expect(get: '/search_records').not_to route_to('search_records#index')
    end

    it 'does not route POST /search_records (create)' do
      expect(post: '/search_records').not_to be_routable
    end

    it 'does not route PATCH /search_records/:id (update)' do
      expect(patch: "/search_records/#{object_id}").not_to be_routable
    end

    it 'does not route DELETE /search_records/:id (destroy)' do
      expect(delete: "/search_records/#{object_id}").not_to be_routable
    end
  end

  describe 'GET /search_records/new', type: :request do
    # :id on the show route is now constrained to a Mongo ObjectId shape, so
    # "new" never matches it and falls through to the site's catch-all page
    # route (pages#show) instead, which renders a plain 404.
    it 'returns 404 without ever instantiating SearchRecordsController' do
      expect(SearchRecordsController).not_to receive(:new)

      get '/search_records/new'

      expect(response).to have_http_status(:not_found)
    end
  end
end
