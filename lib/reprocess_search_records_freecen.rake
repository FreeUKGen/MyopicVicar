namespace :freecen do
  BATCH_SIZE = 100000
  PROGRESS_INTERVAL = 10
  desc "Reprocess batches for a specific county chapman code (e.g. 'rake batches:reprocess_county[YKS]')"
  task :reprocess_search_records_for_a_county, [:chapman_code] => :environment do |t, args|
    require 'freecen_csv_file_incorporate'
    validate_chapman_code(args[:chapman_code])
    chapman_code = args[:chapman_code].upcase

    puts "Starting batch reprocessing for #{ChapmanCode.name_from_code(chapman_code)} (#{chapman_code})"

    begin
      process_batches_for_county(chapman_code)
    rescue => e
      handle_fatal_error(e)
    end
  end

  desc "List all available Chapman codes"
  task list_chapman_codes: :environment do
    display_chapman_codes
  end

  desc "Number of files to be processed for a county"
  task :count_batches_to_be_processed_for_the_county, [:chapman_code] => :environment do |t, args|
    validate_chapman_code(args[:chapman_code])
    chapman_code = args[:chapman_code].upcase

    begin
      count_batches_for_county(chapman_code)
    rescue => e
      handle_fatal_error(e)
    end
  end

  private

  def validate_chapman_code(chapman_code)
    unless chapman_code
      puts "Error: Chapman code is required, rake freecen:reprocess_search_records_for_a_county[CHAPMAN_CODE]"
      exit 1
    end

    unless ChapmanCode.value?(chapman_code.upcase)
      puts "Error: Invalid Chapman code '#{chapman_code}'. Please use one of the following valid chapman codes:#{ChapmanCode.values.join(', ')}"
      exit 1
    end
  end

  def process_batches_for_county(chapman_code)
    batches = FreecenCsvFile.where(chapman_code: chapman_code, incorporated: true).order_by(file_name: 1)
    total_batches = batches.count

    if total_batches.zero?
      puts "No batches found for #{chapman_code}"
      return
    end

    puts "Found #{total_batches} batches to process"

    processed = 0
    failed = []
    start_time = Time.now
    #software_version = get_software_version

    batches.no_timeout.each_slice(BATCH_SIZE) do |batch_group|
      batch_group.each do |batch|
        begin
          process_single_batch(batch, processed + 1, total_batches, chapman_code)
          processed += 1

          if (processed % PROGRESS_INTERVAL).zero?
            print_progress(processed, total_batches, start_time)
          end
        rescue => e
          handle_batch_error(batch, e, failed)
        end
      end
    end

    print_summary(total_batches, processed, failed, start_time)
  end

  def process_single_batch(batch, current, total,chapman_code)
    print "\rProcessing batch #{current}/#{total}: #{batch.file_name}"
    FreecenCsvFileIncorporate.incorporate_records(batch)
  end

  def print_progress(processed, total, start_time)
    elapsed = Time.now - start_time
    avg_time = elapsed / processed
    remaining = avg_time * (total - processed)

    print "\nProgress: #{processed}/#{total} (#{(processed.to_f/total*100).round(1)}%)"
    print " - Est. remaining time: #{format_duration(remaining)}"
  end

  def handle_batch_error(batch, error, failed)
    failed << {
      file_name: batch.file_name,
      error: error.message,
      backtrace: error.backtrace.first(3)
    }
    puts "\nError processing #{batch.file_name}: #{error.message}"
  end

  def print_summary(total_batches, processed, failed, start_time)
    elapsed = Time.now - start_time

    puts "\n\nProcessing complete!"
    puts "----------------------------------------"
    puts "Total batches: #{total_batches}"
    puts "Successfully processed: #{processed}"
    puts "Failed: #{failed.count}"
    puts "Total time: #{format_duration(elapsed)}"
    puts "Average time per batch: #{format_duration(elapsed/processed)}"

    if failed.any?
      puts "\nFailed batches:"
      failed.each do |f|
        puts "- #{f[:file_name]}: #{f[:error]}"
        puts "  Backtrace: #{f[:backtrace].join("\n  ")}"
      end
    end
  end

  def count_batches_for_county(chapman_code)
    puts "Counting batches to be processed for #{ChapmanCode.name_from_code(chapman_code)} (#{chapman_code})"

    total_batches = FreecenCsvFile.where(chapman_code: chapman_code).count

    if total_batches.zero?
      puts "No batches found for #{chapman_code}"
    else
      puts "Found #{total_batches} batches to process"
    end
  end

  def display_chapman_codes
    puts "Available Chapman Codes:"
    puts "----------------------"
    ChapmanCode.values.sort.each do |code|
      puts "#{code}: #{ChapmanCode.name_from_code(code)}"
    end
  end

  def handle_fatal_error(error)
    puts "\nFatal error: #{error.message}"
    puts error.backtrace
    exit 1
  end

  def format_duration(seconds)
    return "0s" if seconds.zero?

    hours = (seconds / 3600).to_i
    minutes = ((seconds % 3600) / 60).to_i
    seconds = (seconds % 60).to_i

    parts = []
    parts << "#{hours}h" if hours > 0
    parts << "#{minutes}m" if minutes > 0
    parts << "#{seconds}s" if seconds > 0 || parts.empty?

    parts.join(" ")
  end
end