require 'spec_helper'

RSpec.describe TransregCsvfilesController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(csvfile: attrs)
    controller.send(meth)
  end

  describe '#csvfile_params (strong parameters)' do
    it 'permits the uploaded file, process and action; strips userid/file_name' do
      result = permitted(:csvfile_params,
                         csvfile: 'f', process: 'Process tonight', action: 'Upload',
                         userid: 'someone_else', file_name: '../../x.csv')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('csvfile', 'process', 'action')
    end
  end
end
