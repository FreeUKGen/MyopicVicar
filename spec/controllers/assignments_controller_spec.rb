require 'spec_helper'

RSpec.describe AssignmentsController, type: :controller do
  describe '#assignment_params (strong parameters)' do
    it 'permits the assignment fields, including the checkbox/multi-select arrays' do
      controller.params = ActionController::Parameters.new(
        assignment: {
          type: 'transcriber',
          source_id: 'src1',
          instructions: 'please transcribe',
          image_server_group_id: 'grp1',
          transcriber_image_file_name: ['img1', 'img2'],
          reviewer_image_file_name: ['img3'],
          user_id: ['user1'],
          # not a declared field on Assignment / not part of this form
          admin: true
        }
      )

      permitted = controller.send(:assignment_params)

      expect(permitted.permitted?).to be true
      expect(permitted[:type]).to eq('transcriber')
      expect(permitted[:transcriber_image_file_name]).to eq(['img1', 'img2'])
      expect(permitted[:user_id]).to eq(['user1'])
      expect(permitted.to_h.keys).not_to include('admin')
    end

    it 'returns nil for the bulk PUT request path (params[:assignment] may be absent there)' do
      controller.params = ActionController::Parameters.new(_method: 'put', type: 'transcriber')

      expect(controller.send(:assignment_params)).to be_nil
    end
  end
end
