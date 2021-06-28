# Manages the collection of site statistics which are the number of search per day and the number of records added and present
class SiteStatisticsController < ApplicationController
  def create
    @site_statistic = SiteStatistic.new(site_statistic_params)
    @site_statistic.save
    if @site_statistic.errors.any?
      flash[:notice] = 'There were errors'
      redirect_to(new_site_statistic_path(@site_statistic)) && return
    end
    redirect_to(site_statistic_path(@site_statistic))
  end

  def edit
    @site_statistic = SiteStatistic.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No such record') && return if @site_statistic.blank?
  end

  def new
    @site_statistic = SiteStatistic.new
  end

  def index
    if appname_downcase == 'freecen'
      redirect_to freecen2_site_statistics_path
    else
      @site_statistics = SiteStatistic.all.order_by(interval_end: -1)
    end
  end

  def show
    @site_statistic = SiteStatistic.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No such record') && return if @site_statistic.blank?
  end

  def update
    @site_statistic = SiteStatistic.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No such record') && return if @site_statistic.blank?
    proceed = @site_statistic.update_attributes(site_statistic_params)
    unless proceed
      flash[:notice] = 'There were errors'
      redirect_to(edit_site_statistic_path(@site_statistic)) && return
    end
    redirect_to(site_statistic_path(@site_statistic))
  end

  private

  def site_statistic_params
    params.require(:site_statistic).permit!
  end
end
