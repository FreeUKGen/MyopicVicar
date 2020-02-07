class CountValentinesMarriages
  class << self
    def process(limit)
      file_for_messages = 'log/count_valentines_marriages.log'
      message_file = File.new(file_for_messages, 'w')
      limit = limit.to_i
      p 'Producing report of the count of valentines marriages'
      message_file.puts 'Producing report of the count of valentines marriages'
      num = 0
      time_start = Time.now
      start = 1500
      finish = 2020
      total = 0
      while start < finish
        date = "#{start}-02-14"
        count_for_year = SearchRecord.where(search_date: date, record_type: 'ma').count
        total = total + count_for_year
        start = start + 1
        num = num + 1
        break if num == limit
      end
      p "#{total} marriages for the period 1500-#{start} "
      message_file.puts "#{total} marriages for the period 1500-#{start} "
      time_elapsed = Time.now - time_start
      p "Finished #{num} years in #{time_elapsed}"
    end
  end
end
