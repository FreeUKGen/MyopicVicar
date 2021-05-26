# Manages the collection of site statistics which are the number of search per day and the number of records added and present
class Freecen2SiteStatisticsController < ApplicationController

  require 'csv'

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

  def export_csv

    start_date = params[:csvdownload][:period_from].to_datetime
    end_date = params[:csvdownload][:period_to].to_datetime

    if params[:csvdownload][:period_from].to_datetime >= params[:csvdownload][:period_to].to_datetime
      message = "End Date must be after Start Date"
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    stats_start = Freecen2SiteStatistic.find_by(interval_end: start_date)
    stats_end = Freecen2SiteStatistic.find_by(interval_end: end_date)

    @stats_array = []
    ChapmanCode.merge_counties.each do |county|
      Freecen::CENSUS_YEARS_ARRAY.each do |census|
        if stats_end.records.dig(county, census).nil?
          @total_individuals  = 0
        else
          @total_individuals = stats_end.records[county][census][:individuals]
        end
        if stats_start.records.dig(county, census).nil?
          @added_individuals =  @total_individuals
        else
          @added_individuals =  @total_individuals - stats_start.records[county][census][:individuals]
        end
        if  @added_individuals < 0
          @added_individuals = 0
        end
        county_name = ChapmanCode.name_from_code(county)
        @stats_array  << [county, county_name, census, @total_individuals,  @added_individuals]
      end
    end

    success, message, file_location, file_name = create_csv_file(@stats_array, start_date, end_date)

    if success
      if File.file?(file_location)
        flash[:notice]  = message unless message.empty?
        send_file(file_location, filename: file_name, x_sendfile: true) && return
      end
    else
      flash[:notice]  = "There was a problem downloading the CSV file"
    end
    redirect_back(fallback_location: new_manage_resource_path)
  end

  def create_csv_file(stats_array, start_date, end_date)
    file = "FreeCen_Stats_#{start_date.strftime("%Y%m%d")}_#{end_date.strftime("%Y%m%d")}.csv"
    file_location = Rails.root.join('tmp', file)
    success, message = write_csv_file(file_location, stats_array)

    [success, message, file_location, file]
  end

  def write_csv_file(file_location, stats_array)
    column_headers =%w(chapman_code county census total_individuals added_individuals)

    CSV.open(file_location, 'wb', { row_sep: "\r\n" }) do |csv|
      csv << column_headers
      stats_array.each do |rec|
        csv << rec
      end
    end
    [true, '']
  end

  def data_download
    @freecen2_site_statistics = Freecen2SiteStatistic.all.order_by(interval_end: -1)
    stats_dates = @freecen2_site_statistics.pluck(:interval_end)
    all_dates = stats_dates.sort.reverse
    all_dates_str = all_dates.map { |date| date.to_datetime.strftime("%d/%b/%Y")}
    array_length = all_dates_str.length
    end_dates = Array.new(all_dates_str)
    end_dates.delete_at(array_length -1)
    start_dates = Array.new(all_dates_str)
    start_dates.delete_at(0)
    @period_start_dates = start_dates
    @period_end_dates = end_dates
  end

  def index
    @freecen2_site_statistics = Freecen2SiteStatistic.all.order_by(interval_end: -1)
    if session[:chapman_code].present?
      @county = session[:county]
      statistics = Freecen2SiteStatistic.all.order_by(interval_end: -1)
      @county_stats = @freecen2_site_statistics[0].records[session[:chapman_code]]
      @inverval_end = @freecen2_site_statistics[0].interval_end
      session[:stats_view] = true
      session[:stats_todate] = @freecen2_site_statistics[0].interval_end
      session.delete(:stats_year)
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
