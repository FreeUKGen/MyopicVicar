require 'spec_helper'

RSpec.describe Freecen1VldFilesController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(freecen1_vld_file: attrs)
    controller.send(meth)
  end

  describe '#freecen1_vld_file_params (strong parameters, edit form)' do
    it 'permits the edit form fields and strips system fields' do
      result = permitted(:freecen1_vld_file_params,
                         transcriber_name: 'T', piece: '5', transcriber_userid: 'u',
                         userid: 'x', num_entries: '1', file_digest: 'd', uploaded_file_location: '/etc')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('transcriber_name', 'piece', 'transcriber_userid')
    end
  end

  describe '#freecen1_vld_file_upload_params (strong parameters, upload form)' do
    it 'permits only the upload form fields' do
      result = permitted(:freecen1_vld_file_upload_params,
                         action: 'Upload', uploaded_file: 'f', dir_name: 'NFK',
                         file_name: 'x.vld', piece: '5', transcriber_userid: 'u')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('action', 'uploaded_file', 'dir_name')
    end
  end
end
