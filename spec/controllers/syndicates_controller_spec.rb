require 'spec_helper'

RSpec.describe SyndicatesController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(syndicate: attrs)
    controller.send(meth)
  end

  describe '#syndicate_params (strong parameters)' do
    it 'permits the form fields and strips the rest' do
      result = permitted(:syndicate_params, syndicate_code: 'S', syndicate_coordinator: 'u', syndicate_description: 'd', accepting_transcribers: 'true', syndicate_notes: 'n', changing_name: true, previous_syndicate_code: 'P', previous_syndicate_coordinator: 'p', syndicate_coordinator_lower_case: 'x', _id: 'y')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('syndicate_code', 'syndicate_coordinator', 'syndicate_description', 'accepting_transcribers', 'syndicate_notes', 'changing_name', 'previous_syndicate_code', 'previous_syndicate_coordinator')
    end
  end
end
