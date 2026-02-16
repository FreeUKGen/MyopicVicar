require 'rails_helper'

RSpec.describe 'SearchQueries', type: :request do
  describe 'GET #new' do
    it 'responds successfully with an HTTP 200 status' do
      get new_search_query_path
      expect(response).to have_http_status(:ok)
    end

    it 'renders the home page' do
      get get root_path
      expect(response).to be_successful
    end
  end
end
