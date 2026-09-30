require 'spec_helper'

RSpec.describe RegistersController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(register: attrs)
    controller.send(meth)
  end

  describe '#register_create_params (strong parameters)' do
    it 'permits the form fields and strips the rest' do
      result = permitted(:register_create_params, register_type: 'PR', quality: 'q', credit: 'c', church_id: 'other', records: '9', transcribers: { a: 1 })
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('register_type', 'quality')
    end
  end

  describe '#register_params (strong parameters)' do
    it 'permits the form fields and strips the rest' do
      result = permitted(:register_params, register_type: 'BT', quality: 'q', status: 's', register_notes: 'n', church_id: 'other', alternate_register_name: 'x', last_amended: 'y')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('quality', 'status', 'register_notes')
    end
  end
end
