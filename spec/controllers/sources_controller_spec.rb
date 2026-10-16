require 'spec_helper'

RSpec.describe SourcesController, type: :controller do
  describe '#source_params (strong parameters)' do
    def permitted(attrs)
      controller.params = ActionController::Parameters.new(source: attrs)
      controller.send(:source_params)
    end

    it 'permits the fields the source forms submit, including original_form' do
      result = permitted(source_name: 'Parish Register', notes: 'n', open_data: 'true', choice: '1',
                         original_form: { type: 'film', name: 'x' }, folder_name: 'f', register_id: 'other')
      expect(result).to be_permitted
      expect(result[:source_name]).to eq('Parish Register')
      expect(result[:original_form].to_h).to eq('type' => 'film', 'name' => 'x')
      expect(result.to_h.keys).not_to include('folder_name', 'register_id')
    end

    it 'strips unsubmitted nested image_server_groups_attributes' do
      result = permitted(source_name: 's', image_server_groups_attributes: { '0' => { group_name: 'g' } })
      expect(result.to_h.keys).not_to include('image_server_groups_attributes')
    end
  end
end
