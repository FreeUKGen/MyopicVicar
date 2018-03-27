class SiteStatisticsController < ApplicationController
  def index
    @site_statistics = SiteStatistic.all.order_by(interval_end: -1)
  end
end
