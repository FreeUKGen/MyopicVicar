require 'spec_helper'

RSpec.describe SoftwareVersionsController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(software_version: attrs)
    controller.send(meth)
  end

  describe '#software_version_params (strong parameters)' do
    it 'permits the form fields and strips the rest' do
      result = permitted(:software_version_params, version: '1.2', type: 'x', server: 's', date_of_update: 'd')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('version')
    end
  end
end
