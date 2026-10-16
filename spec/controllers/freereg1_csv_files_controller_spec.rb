require 'spec_helper'

RSpec.describe Freereg1CsvFilesController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(freereg1_csv_file: attrs)
    controller.send(meth)
  end

  describe '#freereg1_csv_file_params (strong parameters)' do
    it 'permits the batch edit form fields and strips ownership/location/system fields' do
      result = permitted(:freereg1_csv_file_params,
                         transcriber_name: 'T', credit_email: 'c@x', transcription_date: '01 Jan 2000',
                         locked_by_transcriber: 'true',
                         userid: 'someone_else', chapman_code: 'SFK', place: 'Elsewhere', register_id: 'r',
                         error: '0', processed: 'false', digest: 'd')
      expect(result).to be_permitted
      expect(result[:transcriber_name]).to eq('T')
      expect(result[:locked_by_transcriber]).to eq('true')
      expect(result.to_h.keys).not_to include('userid', 'chapman_code', 'place', 'register_id', 'error', 'processed', 'digest')
    end
  end
end
