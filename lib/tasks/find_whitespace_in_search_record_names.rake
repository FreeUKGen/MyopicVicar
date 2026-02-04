namespace :search_records do
    desc "Find all SearchRecord documents with leading/trailing whitespace in names"
    task find_whitespace_in_names: :environment do
      puts "Searching for SearchRecord documents with whitespace in names..."
      puts "=" * 80
      
      records_with_whitespace = []
      total_checked = 0
      transcript_names_issues = 0
      search_names_issues = 0
      
      SearchRecord.no_timeout.each do |record|
        total_checked += 1
        issues = []
        
        # Check transcript_names array
        if record.transcript_names.present?
          record.transcript_names.each_with_index do |name_hash, index|
            first_name = name_hash['first_name'] || name_hash[:first_name]
            last_name = name_hash['last_name'] || name_hash[:last_name]
            
            if first_name.present? && (first_name != first_name.strip)
              issues << "transcript_names[#{index}].first_name: '#{first_name}'"
              transcript_names_issues += 1
            end
            
            if last_name.present? && (last_name != last_name.strip)
              issues << "transcript_names[#{index}].last_name: '#{last_name}'"
              transcript_names_issues += 1
            end
          end
        end
        
        # Check search_names embedded documents
        if record.search_names.present?
          record.search_names.each_with_index do |search_name, index|
            if search_name.first_name.present? && (search_name.first_name != search_name.first_name.strip)
              issues << "search_names[#{index}].first_name: '#{search_name.first_name}'"
              search_names_issues += 1
            end
            
            if search_name.last_name.present? && (search_name.last_name != search_name.last_name.strip)
              issues << "search_names[#{index}].last_name: '#{search_name.last_name}'"
              search_names_issues += 1
            end
          end
        end
        
        if issues.any?
          records_with_whitespace << {
            id: record.id.to_s,
            line_id: record.line_id,
            issues: issues
          }
        end
        
        # Progress indicator
        if total_checked % 10000 == 0
          puts "Checked #{total_checked} records... Found #{records_with_whitespace.length} with whitespace issues"
        end
      end
      
      # Report results
      puts "\n" + "=" * 80
      puts "SUMMARY"
      puts "=" * 80
      puts "Total records checked: #{total_checked}"
      puts "Records with whitespace issues: #{records_with_whitespace.length}"
      puts "Total transcript_names issues: #{transcript_names_issues}"
      puts "Total search_names issues: #{search_names_issues}"
      
      if records_with_whitespace.any?
        puts "\n" + "=" * 80
        puts "DETAILED RESULTS (first 50 records)"
        puts "=" * 80
        
        records_with_whitespace.first(50).each do |record_info|
          puts "\nRecord ID: #{record_info[:id]}"
          puts "Line ID: #{record_info[:line_id]}" if record_info[:line_id]
          puts "Issues:"
          record_info[:issues].each do |issue|
            puts "  - #{issue}"
          end
        end
        
        if records_with_whitespace.length > 50
          puts "\n... and #{records_with_whitespace.length - 50} more records with issues"
        end
        
        # Write full results to file
        output_file = Rails.root.join('log', 'search_records_with_whitespace.txt')
        File.open(output_file, 'w') do |f|
          f.puts "SearchRecord Documents with Leading/Trailing Whitespace in Names"
          f.puts "Generated: #{Time.now}"
          f.puts "=" * 80
          f.puts "\n"
          
          records_with_whitespace.each do |record_info|
            f.puts "Record ID: #{record_info[:id]}"
            f.puts "Line ID: #{record_info[:line_id]}" if record_info[:line_id]
            f.puts "Issues:"
            record_info[:issues].each do |issue|
              f.puts "  - #{issue}"
            end
            f.puts "-" * 80
          end
        end
        
        puts "\nFull results written to: #{output_file}"
      else
        puts "\nNo records found with whitespace issues!"
      end
    end
  end