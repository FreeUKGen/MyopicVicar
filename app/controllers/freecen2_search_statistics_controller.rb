class Freecen2SearchStatisticsController < ApplicationController
  skip_before_action :require_login

  require 'csv'

  LAUNCH = [2015, 4, 14, 14]

  def graphic
    calculate_last_8_days(8)
    if params[:hours]
      #       over-write with recent stuff
      calculate_last_48_hours(params[:hours])
    end

    #     calculate_last_48_hours
  end

  def index
    @freecen2_search_statistics = Freecen2SearchStatistic.where(:searches.ne => 0).desc(:interval_end).limit(100)
    @period_start_dates, @period_end_dates = get_stats_dates
  end

  def show

  end

  def calculate_last_8_days(days)
    days = [days_from_launch, days.to_i].min
    points = days + 1
    @chart_unit = "#{days} days"
    @label = [''] * points #initialize blank labels
    fields = [:searches, :time_gt_1s, :time_gt_10s, :time_gt_60s, :ln, :fn, :zero_result, :limit_result, :zero_county, :date, :record_type, :place, :nearby]
    @data = {}
    fields.each { |field| @data[field] = [0]*points }  #initialize data array
    (points-1).downto(0) do |i_ago|
      date = (Time.now) - i_ago.day
      i = points - i_ago - 1 #TODO make not horrible
      @label[i] = date.strftime("%d %b %Y")
      day_stats = Freecen2SearchStatistic.where(:year => date.year, :month => date.month, :day => date.day)

      day_stats.each do |stat|
        fields.each do |field|
          @data[field][i] += stat.send(field)
        end
      end
    end
    # convert the percentages
    absolute_fields = [:searches, :time_gt_1s, :time_gt_10s, :time_gt_60s]
    fields.each do |field|
      unless absolute_fields.include? field
        0.upto(@data[field].size) do |i|
          @data[field][i] =  (100 * @data[field][i].to_f /  @data[:searches][i].to_f).ceil if @data[:searches][i] && @data[:searches][i] > 0
        end
      end
    end
  end

  def calculate_last_48_hours(hours)
    hours = [hours_from_launch, hours.to_i].min
    points = hours + 1
    @chart_unit = "#{hours} hours"
    @label = [''] * points #initialize blank labels
    fields = [:searches, :time_gt_1s, :time_gt_10s, :time_gt_60s]
    @data = {}
    fields.each { |field| @data[field] = [0]*points }  #initialize data array
    (points-1).downto(0) do |i_ago|
      date = Time.now - i_ago.hour
      i = points - i_ago - 1
      @label[i] = date.hour.to_s
      day_stats = Freecen2SearchStatistic.where(:year => date.year, :month => date.month, :day => date.day, :hour => date.hour)

      day_stats.each do |stat|
        fields.each do |field|
          @data[field][i] += stat.send(field)
        end
      end
    end
  end

  def days_from_launch
    (hours_from_launch / 24).to_i
  end

  def hours_from_launch
    seconds_from_launch = Time.now - Time.new(LAUNCH[0], LAUNCH[1], LAUNCH[2], LAUNCH[3])
    (seconds_from_launch / 3600).to_i
  end

  def export_csv
    start_date = params[:csvdownload][:period_from].to_datetime
    end_date = params[:csvdownload][:period_to].to_datetime

    if params[:csvdownload][:period_from].to_datetime >= params[:csvdownload][:period_to].to_datetime
      message = 'End Date must be after Start Date'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    @report_array = []

    report_recs = Freecen2SearchStatistic.between(interval_end: start_date..end_date)

    report_recs.each do |report_rec|
      @report_array << [report_rec.interval_end.strftime('%d/%b/%Y'), report_rec.searches, report_rec.zero_result, report_rec.limit_result, report_rec.ln, report_rec.fn, report_rec.place, report_rec.nearby, report_rec.fuzzy, report_rec.zero_county, report_rec.one_county, report_rec.multi_county, report_rec.date, report_rec.record_type, report_rec.zero_birth_chapman_codes, report_rec.one_birth_chapman_codes, report_rec.multi_birth_chapman_codes, report_rec.disabled, report_rec.marital_status, report_rec.sex, report_rec.language, report_rec.occupation]
    end

    success, message, file_location, file_name = create_csv_file(@report_array, start_date, end_date)

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

  def create_csv_file(report_array, start_date, end_date)
    file = "FreeCen2_SearchStats_#{start_date.strftime('%Y%m%d')}_#{end_date.strftime('%Y%m%d')}.csv"
    file_location = Rails.root.join('tmp', file)
    success, message = write_csv_file(file_location, report_array)

    [success, message, file_location, file]
  end

  def write_csv_file(file_location, report_array)
    column_headers = %w[End_date Searches Zero_results Maxed_out Surname Forename Place Nearby Fuzzy Zero_county One_county Multiple_counties Date Census_year Zero_birth One_birth Multiple_birth Disabled Marital Sex Language Occupation]
    CSV.open(file_location, 'wb', { row_sep: "\r\n" }) do |csv|
      csv << column_headers
      report_array.each do |rec|
        csv << rec
      end
    end
    [true, '']
  end

  def get_stats_dates
    stats_dates = @freecen2_search_statistics.pluck(:interval_end)
    all_dates = stats_dates.sort.reverse
    all_dates_str = all_dates.map { |date| date.to_datetime.strftime('%d/%b/%Y') }
    array_length = all_dates_str.length
    end_dates = Array.new(all_dates_str)
    end_dates.delete_at(array_length - 1)
    start_dates = Array.new(all_dates_str)
    start_dates.delete_at(0)
    [start_dates, end_dates]
  end
end
