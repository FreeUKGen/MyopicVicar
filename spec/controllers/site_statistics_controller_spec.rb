require 'spec_helper'

RSpec.describe SiteStatisticsController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(site_statistic: attrs)
    controller.send(meth)
  end

  describe '#site_statistic_params (strong parameters)' do
    it 'permits the form fields and strips the rest' do
      result = permitted(:site_statistic_params, year: '2024', month: '1', day: '2', n_records: '5', n_searches: '3', n_records_added: '1', county_stats: { a: 1 }, interval_end: 'x', n_records_1881: '4')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('year', 'month', 'day', 'n_records', 'n_searches', 'n_records_added')
    end
  end
end
