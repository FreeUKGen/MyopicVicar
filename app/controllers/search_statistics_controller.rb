class SearchStatisticsController < InheritedResources::Base
  skip_before_filter :require_login
  
  
  def index
     calculate_last_8_days   
     if params[:hours]
#       over-write with recent stuff
       calculate_last_48_hours(params[:hours])   
       
     end
       
#     calculate_last_48_hours   
  end
  
  def calculate_last_8_days
    points = 3
    @chart_unit = "#{points} days"
    @label = []
    fields = [:n_searches, :n_time_gt_1s, :n_time_gt_10s, :n_time_gt_60s]
    @data = {}
    fields.each { |field| @data[field] = [0]*points }  #initialize data array
    (points-1).downto(0) do |i|
      date = Time.now - i.day
      @label << date.day.to_s
      day_stats = SearchStatistic.where(:year => date.year, :month => date.month, :day => date.day)
      
      day_stats.each do |stat|
        fields.each do |field|
          @data[field][i] += stat.send(field)
        end
      end
    end
  end

  def calculate_last_48_hours(hours)
    points = hours.to_i + 1
    @chart_unit = "#{hours} hours"
    @label = []
    fields = [:n_searches, :n_time_gt_1s, :n_time_gt_10s, :n_time_gt_60s]
    @data = {}
    fields.each { |field| @data[field] = [0]*points }  #initialize data array
    (points-1).downto(0) do |i|
      date = Time.now - i.hour
      @label << date.hour.to_s
      day_stats = SearchStatistic.where(:year => date.year, :month => date.month, :day => date.day, :hour => date.hour)
      
      day_stats.each do |stat|
        fields.each do |field|
          @data[field][i] += stat.send(field)
        end
      end
    end
  end
end
