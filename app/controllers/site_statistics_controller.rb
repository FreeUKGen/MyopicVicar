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

  def export_csv
    start_date = params[:csvdownload][:period_from].to_datetime
    end_date = params[:csvdownload][:period_to].to_datetime

    if start_date >= end_date
      message = 'End Date must be after Start Date'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    report_start = SiteStatistic.find_by(interval_end: start_date)
    report_end = SiteStatistic.find_by(interval_end: end_date)
    ChapmanCode.merge_counties.each do |county|
      RRecordType::ALL_FREEREG_TYPES.each do |type|
        @total_search_records = report_end.records.dig(county, type).nil? ? 0 : report_end.records[county][type][:search_records]
        @added_search_records= report_start.records.dig(county, type).nil? ? @total_search_records: @total_search_records - report_start.records[county][type][:search_records]
        @added_search_records = 0 if @added_search_records.negative?

        county_name = ChapmanCode.name_from_code(county)
        @report_array << [county, county_name, type, @total_search_records, @added_search_records]
      end
    end

    success, message, file_location, file_name = SiteStatistic.create_csv_file(start_date, end_date)

    if success
      if File.file?(file_location)
        flash[:notice] = message unless message.empty?
        send_file(file_location, filename: file_name, x_sendfile: true) && return
      end
    else
      flash[:notice] = 'There was a problem downloading the CSV file'
    end
    redirect_back(fallback_location: new_manage_resource_path)
  end

  def index
    if appname_downcase == 'freecen'
      redirect_to freecen2_site_statistics_path
    else
      @site_statistics = SiteStatistic.all.order_by(interval_end: -1)
    end
    @period_start_dates, @period_end_dates = SiteStatistic.get_stats_dates
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
