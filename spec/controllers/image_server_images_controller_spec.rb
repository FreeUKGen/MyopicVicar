require 'spec_helper'

RSpec.describe ImageServerImagesController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(image_server_image: attrs)
    controller.send(meth)
  end

  describe '#image_server_image_params (strong parameters)' do
    it 'permits the edit/move/flush form fields and strips the rest' do
      result = permitted(:image_server_image_params,
                         id: 'i', image_server_group_id: 'g', orig_image_server_group_id: 'o', origin: 'edit',
                         status: 'a', difficulty: 'd', notes: 'n', image_file_name: 'f.jpg',
                         transcriber: ['x'], reviewer: ['y'], assignment_id: 'as', order: '1')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('id', 'image_server_group_id', 'orig_image_server_group_id', 'origin',
                                                  'status', 'difficulty', 'notes', 'image_file_name')
    end

    it 'permits id as an array (move/flush check boxes)' do
      expect(permitted(:image_server_image_params, id: %w[a b], origin: 'move')[:id]).to eq(%w[a b])
    end

    it 'returns the same object each call so update can delete origin before mass-assigning' do
      permitted(:image_server_image_params, origin: 'edit', orig_image_server_group_id: 'o', status: 'a')
      controller.send(:image_server_image_params).delete(:origin)
      controller.send(:image_server_image_params).delete(:orig_image_server_group_id)
      expect(controller.send(:image_server_image_params).to_h).to eq('status' => 'a')
    end
  end
end
