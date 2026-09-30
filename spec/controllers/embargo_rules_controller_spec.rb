require 'spec_helper'

RSpec.describe EmbargoRulesController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(embargo_rule: attrs)
    controller.send(meth)
  end

  describe '#embargo_rule_params (strong parameters)' do
    it 'permits the form fields and strips the rest' do
      result = permitted(:embargo_rule_params, register_id: 'r', member_who_created: 'm', record_type: 'ba', rule: 'x', period: '10', period_type: 'period', authority: 'a', reason: 'why', _id: 'x', created_at: 'c')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('register_id', 'member_who_created', 'record_type', 'rule', 'period', 'period_type', 'authority', 'reason')
    end
  end
end
