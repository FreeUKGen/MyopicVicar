require 'spec_helper'

RSpec.describe FreecenCsvFilesController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(freecen_csv_file: attrs)
    controller.send(meth)
  end

  describe '#freecen_csv_file_params (strong parameters)' do
    it 'permits the edit form fields and strips ownership/piece/system fields' do
      result = permitted(:freecen_csv_file_params,
                         transcriber_name: 'T', locked_by_coordinator: 'true', incorporation_lock: 'false',
                         incorporating_lock: 'false', userid: 'x', freecen2_piece_id: 'p', incorporated: 'true',
                         total_errors: '0', validation: 'true')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('transcriber_name', 'locked_by_coordinator',
                                                  'incorporation_lock', 'incorporating_lock')
    end
  end
end
