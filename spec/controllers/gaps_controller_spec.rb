require 'spec_helper'

RSpec.describe GapsController, type: :controller do
  describe '#gap_params (strong parameters)' do
    it 'permits the gap form fields' do
      controller.params = ActionController::Parameters.new(
        gap: {
          record_type: 'Baptisms',
          freereg1_csv_file: 'file1',
          start_date: '1850',
          end_date: '1860',
          reason: 'Missing register',
          note: 'a note',
          register: 'reg1',
          # not a declared field on Gap
          admin: true
        }
      )

      permitted = controller.send(:gap_params)

      expect(permitted.permitted?).to be true
      expect(permitted[:record_type]).to eq('Baptisms')
      expect(permitted[:reason]).to eq('Missing register')
      expect(permitted[:register]).to eq('reg1')
      expect(permitted.to_h.keys).not_to include('admin')
    end

    it 'returns nil when params[:_method] is put' do
      controller.params = ActionController::Parameters.new(_method: 'put', gap: { note: 'x' })

      expect(controller.send(:gap_params)).to be_nil
    end
  end
end
