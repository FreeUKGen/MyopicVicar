require 'spec_helper'

RSpec.describe Freecen2SiteStatisticsController, type: :controller do
  def permitted(meth, attrs)
    controller.params = ActionController::Parameters.new(freecen2_site_statistic: attrs)
    controller.send(meth)
  end

  describe '#freecen2_site_statistic_params (strong parameters)' do
    it 'permits the date fields and strips computed totals' do
      result = permitted(:freecen2_site_statistic_params,
                         year: '2024', month: '1', day: '2', searches: '5', records: { 'NFK' => 1 },
                         interval_end: '2024-01-02')
      expect(result).to be_permitted
      expect(result.to_h.keys).to contain_exactly('year', 'month', 'day')
    end
  end
end
