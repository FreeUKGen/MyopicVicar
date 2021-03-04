# Manages the collection of site statistics which are the number of search per day and the number of records added and present
class Freecen2SiteStatisticsController < ApplicationController
  def create
    @freecen2_site_statistic = Freecen2SiteStatistic.new(freecen2_site_statistic_params)
    @freecen2_site_statistic.save
    if @freecen2_site_statistic.errors.any?
      flash[:notice] = 'There were errors'
      redirect_to(new_freecen2_site_statistic_path(@freecen2_site_statistic)) && return
    end
    redirect_to(freecen2_site_statistic_path(@freecen2_site_statistic))
  end

  def edit
    @freecen2_site_statistic = Freecen2SiteStatistic.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No such record') && return if @freecen2_site_statistic.blank?
  end

  def new
    @freecen2_site_statistic = Freecen2SiteStatistic.new
  end

  def index
    @freecen2_site_statistics = Freecen2SiteStatistic.all.order_by(interval_end: -1)
    if session[:chapman_code].present?
      @county = session[:county]
      statistics = Freecen2SiteStatistic.all.order_by(interval_end: -1)
      @county_stats = @freecen2_site_statistics[0].records[session[:chapman_code]]
      @inverval_end = @freecen2_site_statistics[0].interval_end
      p @inverval_end
      p @county_stats
      render :index_county
    else
      @county = session[:county].present? ? session[:county] : 'total'
    end
  end

  def show
    @freecen2_site_statistic = Freecen2SiteStatistic.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No such record') && return if @freecen2_site_statistic.blank?
  end

  def update
    @freecen2_site_statistic = Freecen2SiteStatistic.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No such record') && return if @freecen2_site_statistic.blank?
    proceed = @freecen2_site_statistic.update_attributes(freecen2_site_statistic_params)
    unless proceed
      flash[:notice] = 'There were errors'
      redirect_to(edit_freecen2_site_statistic_path(@freecen2_site_statistic)) && return
    end
    redirect_to(freecen2_site_statistic_path(@freecen2_site_statistic))
  end

  private

  def freecen2_site_statistic_params
    params.require(:freecen2_site_statistic).permit!
  end
end
