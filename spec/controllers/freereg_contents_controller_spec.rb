require 'spec_helper'

RSpec.describe FreeregContentsController, type: :controller do
  describe 'GET unique_church_names' do
    let(:church_id) { 'church-id' }

    before do
      allow(controller).to receive(:load_last_stat)
    end

    it 'redirects when the ChurchUniqueName has no corresponding Church' do
      summary = double('church unique name', unique_forenames: [], unique_surnames: [])
      allow(ChurchUniqueName).to receive(:find_by).with(church_id: church_id).and_return(summary)
      allow(Church).to receive(:find_by).with(_id: church_id).and_return(nil)

      get :unique_church_names, params: { id: church_id }

      expect(response).to redirect_to(new_freereg_content_path)
      expect(flash[:notice]).to eq('That place does not exist')
    end

    it 'redirects when the ID does not identify a ChurchUniqueName or Church' do
      allow(ChurchUniqueName).to receive(:find_by).with(church_id: church_id).and_return(nil)
      allow(Church).to receive(:find_by).with(_id: church_id).and_return(nil)

      get :unique_church_names, params: { id: church_id }

      expect(response).to redirect_to(new_freereg_content_path)
      expect(flash[:notice]).to eq('That place does not exist')
    end

    it 'continues normally when both the ChurchUniqueName and Church exist' do
      summary = double('church unique name', unique_forenames: ['Jane'], unique_surnames: ['Doe'])
      church = double('church')
      allow(ChurchUniqueName).to receive(:find_by).with(church_id: church_id).and_return(summary)
      allow(Church).to receive(:find_by).with(_id: church_id).and_return(church)
      expect(controller).to receive(:variables_for_church_show)

      get :unique_church_names, params: { id: church_id }

      expect(response).to have_http_status(:ok)
    end
  end
end
