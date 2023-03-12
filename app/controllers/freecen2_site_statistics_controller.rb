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
    report_type = params[:csvdownload][:report_type]

    if params[:csvdownload][:period_from].to_datetime >= params[:csvdownload][:period_to].to_datetime
      message = 'End Date must be after Start Date'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    @report_array = []
    case report_type
    when 'search_records'
      report_start = Freecen2SiteStatistic.find_by(interval_end: start_date)
      report_end = Freecen2SiteStatistic.find_by(interval_end: end_date)
      ChapmanCode.merge_counties.each do |county|
        Freecen::CENSUS_YEARS_ARRAY.each do |census|
          @total_search_records = report_end.records.dig(county, census).nil? ? 0 : report_end.records[county][census][:search_records]
          @added_search_records= report_start.records.dig(county, census).nil? ? @total_search_records: @total_search_records - report_start.records[county][census][:search_records]
          @added_search_records = 0 if @added_search_records.negative?

          county_name = ChapmanCode.name_from_code(county)
          @report_array << [county, county_name, census, @total_search_records, @added_search_records]
        end
      end

    when 'pieces'
      report_pieces = Freecen2Piece.between_dates_pieces_online(start_date, end_date)
      if report_pieces.size.positive?
        report_pieces.each do |entry|
          @report_array << entry
        end
      else
        @report_array << ['No Pieces found']
      end
    end

    success, message, file_location, file_name = create_csv_file(@report_array, report_type, start_date, end_date)

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

  def create_csv_file(report_array, report_type, start_date, end_date)
    case report_type
    when 'search_records'
      rep_lead = 'FreeCen_SearchRecords_'
    when 'pieces'
      rep_lead = 'FreeCen_Pieces_'
    end
    file = "#{rep_lead}#{start_date.strftime('%Y%m%d')}_#{end_date.strftime('%Y%m%d')}.csv"
    file_location = Rails.root.join('tmp', file)
    success, message = write_csv_file(file_location, report_array, report_type)

    [success, message, file_location, file]
  end

  def write_csv_file(file_location, report_array, report_type)
    case report_type
    when 'search_records'
      column_headers = %w[chapman_code county census total_search_records added_search_records]
    when 'pieces'
      column_headers = %w[chapman_code year number name civil_parishes status date records]
    end
    CSV.open(file_location, 'wb', { row_sep: "\r\n" }) do |csv|
      csv << column_headers
      report_array.each do |rec|
        csv << rec
      end
    end
    [true, '']
  end

  def get_stats_dates
    stats_dates = @freecen2_site_statistics.pluck(:interval_end)
    all_dates = stats_dates.sort.reverse
    all_dates_str = all_dates.map { |date| date.to_datetime.strftime("%d/%b/%Y") }
    array_length = all_dates_str.length
    end_dates = Array.new(all_dates_str)
    end_dates.delete_at(array_length - 1)
    start_dates = Array.new(all_dates_str)
    start_dates.delete_at(0)
    [start_dates, end_dates]
  end

  def grand_totals
    @freecen2_site_statistics = Freecen2SiteStatistic.order_by(interval_end: -1).first
    @freecen2_contents = Freecen2Content.order(interval_end: :desc).first
    @interval_end = @freecen2_contents.interval_end
  end

  def index
    @freecen2_site_statistics = Freecen2SiteStatistic.all.order_by(interval_end: -1)
    if session[:chapman_code].present?
      @county = session[:county]
      @county_stats = @freecen2_site_statistics[0].records[session[:chapman_code]]
      @inverval_end = @freecen2_site_statistics[0].interval_end
      session[:stats_view] = true
      session[:stats_todate] = @freecen2_site_statistics[0].interval_end
      session.delete(:stats_year)
      render :index_county
    else
      @county = session[:county].present? ? session[:county] : 'total'
    end

    @period_start_dates, @period_end_dates = get_stats_dates
  end

  def list_pieces
    @county = session[:county]
    @chapman_code = session[:chapman_code]
    @year = params[:stats_year]
    @sorted_by = params[:sorted_by].blank? ? 'Piece Number' : params[:sorted_by]
    case @sorted_by
    when 'Piece Number'
      @freecen2_pieces = Freecen2Piece.where(chapman_code: @chapman_code, year: @year).order_by('number ASC')
    when 'Piece Name'
      @freecen2_pieces = Freecen2Piece.where(chapman_code: @chapman_code, year: @year).order_by('name ASC')
    when 'Date Online'
      @freecen2_pieces = Freecen2Piece.where(chapman_code: @chapman_code, year: @year).order_by('status_date DESC, number ASC')
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
