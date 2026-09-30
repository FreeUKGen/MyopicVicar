require 'spec_helper'

RSpec.describe CsvfilesController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(csvfile: attrs)
    controller.send(meth)
  end

  describe '#csvfile_params (strong parameters)' do
    it 'permits the upload form fields and strips the rest' do
      result = permitted(:csvfile_params,
                         action: 'Upload', csvfile: 'f', type_of_processing: 'Information', userid: 'u',
                         file_name: '../../etc/passwd', process: 'As soon as you can')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('action', 'csvfile', 'type_of_processing', 'userid')
    end
  end
end
