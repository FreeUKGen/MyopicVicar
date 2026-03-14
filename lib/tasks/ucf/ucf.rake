namespace :ucf do
  # ============================================================================
  # Rake task to generate UCF statistics
  # ============================================================================
  #
  # rake ucf:ucf_statistics
  #
  # ============================================================================
  desc "Generate UCF statistics report"
  task :ucf_statistics => :environment do
    places = Place.where("ucf_list" => { "$exists" => true, "$ne" => {} })

    stats = {
      total_places_with_ucf: places.count,
      total_ucf_records: 0,
      total_ucf_files: 0,
      largest_ucf_lists: []
    }

    places.no_timeout.batch_size(500).each do |place|
      record_ids = Array(place.ucf_record_ids)
      ucf_hash   = place.ucf_list.is_a?(Hash) ? place.ucf_list : {}

      record_count = record_ids.size
      file_count   = ucf_hash.keys.size

      stats[:total_ucf_records] += record_count
      stats[:total_ucf_files]   += file_count

      stats[:largest_ucf_lists] << {
        place: "#{place.chapman_code}/#{place.place_name}",
        records: record_count,
        files: file_count
      }
    end

    stats[:largest_ucf_lists] =
      stats[:largest_ucf_lists].sort_by { |p| [-p[:records], -p[:files]] }.take(20)

    puts JSON.pretty_generate(stats)
  end


  # ============================================================================
  # Task name: ucf:validate_ucf_lists
  # ============================================================================
  #
  # Arguments:
  #   limit       → how many Place records to check
  #   fix         → whether to automatically fix issues ("fix")
  #
  # Detect and fix stale UCF lists
  #   - detects orphaned file/record ID
  #   - finds location mismatches
  #   - can auto-fix issues
  #
  # Dry run
  # rake ucf:validate_ucf_lists
  # rake ucf:validate_ucf_lists[1000]
  #
  # Fix issues
  # rake ucf:validate_ucf_lists[0,fix]
  #
  # ============================================================================
  desc "Validate UCF lists for consistency"
  task :validate_ucf_lists, [:limit, :fix] => [:environment] do |t, args|
    limit        = args.limit.to_i
    apply_fixes  = args.fix == "fix"
    issues       = []

    Place.data_present.limit(limit).each do |place|
      original_ucf = place.ucf_list || {}
      updated_ucf  = original_ucf.deep_dup
      changed      = false

      # BATCH 1 — Collect all file IDs for this Place
      file_ids = original_ucf.keys
      existing_files = Freereg1CsvFile.where(:id.in => file_ids).to_a
      existing_file_ids = existing_files.map { |f| f.id.to_s }.to_set

      # BATCH 2 — Collect all record IDs for this Place
      record_ids = original_ucf.values.flatten
      existing_records = SearchRecord.where(:id.in => record_ids).pluck(:id)
      existing_record_ids = existing_records.map(&:to_s).to_set

      # CHECK 1 — Orphaned file IDs
      file_ids.each do |file_id|
        unless existing_file_ids.include?(file_id)
          issues << {
            place_id: place.id.to_s,
            issue: "Orphaned file ID in ucf_list",
            file_id: file_id
          }

          if apply_fixes
            updated_ucf.delete(file_id)
            changed = true
          end
        end
      end

      # CHECK 2 — Orphaned record IDs
      updated_ucf.each do |file_id, ids|
        # next unless ids.is_a?(Array)

        # --- Handle type mismatch ---
        if !ids.is_a?(Array)
          issues << {
            place_id: place.id.to_s,
            issue: "Invalid type in ucf_list value",
            file_id: file_id,
            actual_type: ids.class.name,
            value_sample: ids.inspect
          }

          if apply_fixes
            # Options:
            # A) Convert Hash to empty array (minimal fix)
            # B) Delete entire entry (aggressive fix)
            # Using option A to match new Place#update_ucf_list semantics
            ucf_list[file.id.to_s] = []
            # updated_ucf.delete(file_id) # D) alternate approach
            changed = true
          end
          next
        end

        # Orphaned record IDs (Array case)
        valid_ids = ids.select { |rid| existing_record_ids.include?(rid) }

        if valid_ids.size != ids.size
          (ids - valid_ids).each do |missing|
            issues << {
              place_id: place.id.to_s,
              issue: "Orphaned record ID",
              file_id: file_id,
              record_id: missing
            }
          end

          if apply_fixes
            updated_ucf[file_id] = valid_ids
            changed = true
          end
        end
      end

      # CHECK 3 — File location mismatch
      # ---------------------------------------------------------
      #
      file_lookup = existing_files.index_by { |f| f.id.to_s }

      updated_ucf.keys.each do |file_id|
        file = file_lookup[file_id]
        next unless file

        file_loc  = [file.chapman_code, file.place]
        place_loc = [place.chapman_code, place.place_name]

        if file_loc != place_loc
          issues << {
            place_id: place.id.to_s,
            issue: "File location mismatch",
            file_id: file_id,
            file_place: "#{file.chapman_code}/#{file.place}",
            place: "#{place.chapman_code}/#{place.place_name}"
          }
        end
      end

      # APPLY FIXES (single atomic update)
      if apply_fixes && changed
        place.set(ucf_list: updated_ucf)
      end
    end

    # WRITE REPORT
    timestamp = Time.now.to_i
    path = "log/ucf_validation_#{timestamp}.json"

    File.write(path, JSON.pretty_generate(issues))
    puts "Found #{issues.size} issues. Report: #{path}"
  end


  # ============================================================================
  # DETAILED ORPHAN REPORT - MongoDB Aggregation with Grouping - orphaned files only
  # ============================================================================
  #
  # WHY THIS EXISTS:
  # The optimized task is fast but focused on fixing. This task provides
  # detailed reporting:
  # - Which places reference orphaned files
  # - How many records each orphaned file claims
  # - Grouped by issue type for easier analysis
  #
  # USAGE:
  #   rake ucf:validate_ucf_lists_detailed_report
  #
  # ============================================================================
  desc "Detailed orphan report with place information"
  task :validate_ucf_lists_detailed_report => :environment do
    puts "\n[UCF:REPORT] Building detailed orphan report...\n"

    # Extract all file IDs (same aggregation as optimized task)
    pipeline = [
      { '$project' => { 'ucf_list' => 1 } },
      { '$project' => { 'file_pairs' => { '$objectToArray' => '$ucf_list' } } },
      { '$unwind' => '$file_pairs' },
      { '$group' => { '_id' => '$file_pairs.k' } }
    ]

    all_referenced_file_ids = Place.collection
                                   .aggregate(pipeline)
                                   .map { |doc| doc['_id'].to_s }
                                   .to_set

    # Find orphaned files
    existing_file_ids = Freereg1CsvFile.where(:id.in => all_referenced_file_ids.to_a)
                                       .pluck(:id)
                                       .map(&:to_s)
                                       .to_set

    orphaned_file_ids = all_referenced_file_ids - existing_file_ids

    puts "[UCF:REPORT] Total unique file IDs in ucf_lists: #{all_referenced_file_ids.size}"
    puts "[UCF:REPORT] Files that exist: #{existing_file_ids.size}"
    puts "[UCF:REPORT] Orphaned files: #{orphaned_file_ids.size}\n"

    if orphaned_file_ids.empty?
      puts "[UCF:REPORT] No orphaned files found!"
      next
    end

    # Detailed report per orphaned file
    puts "[UCF:REPORT] " + "="*70
    puts "[UCF:REPORT] DETAILED ORPHANED FILE REPORT"
    puts "[UCF:REPORT] " + "="*70 + "\n"

    orphaned_file_ids.each do |orphaned_id|
      # Find all places that reference this orphaned file
      places_with_orphan = Place.where('ucf_list' => { '$exists' => true })
                                .where("ucf_list.#{orphaned_id}" => { '$exists' => true })
                                .pluck(:id, :place_name, :chapman_code)

      record_count = Place.collection
                          .aggregate([
          { '$match' => { "ucf_list.#{orphaned_id}" => { '$exists' => true } } },
          { '$project' => { 'records' => { '$size' => "$ucf_list.#{orphaned_id}" } } },
          { '$group' => { '_id' => nil, 'total' => { '$sum' => '$records' } } }
        ])
                          .first&.fetch('total', 0) || 0

      puts "[UCF:REPORT] File ID: #{orphaned_id}"
      puts "[UCF:REPORT]   Referenced by: #{places_with_orphan.size} places"
      puts "[UCF:REPORT]   Total claimed records: #{record_count}"
      puts "[UCF:REPORT]   Places:"

      places_with_orphan.each do |(place_id, place_name, chapman_code)|
        puts "[UCF:REPORT]     - #{place_name} (#{chapman_code}) [#{place_id}]"
      end

      puts
    end

    puts "[UCF:REPORT] " + "="*70
    puts "[UCF:REPORT] Report complete.\n"
  end


  # ============================================================================
  # OPTIMIZED ORPHAN DETECTION using MongoDB Aggregation - quiet, fast
  # ============================================================================
  #
  # WHY THIS EXISTS:
  # The original validate_ucf_lists task iterates through each place and checks
  # for orphaned files/records. With 10,000+ places, this causes thousands of
  # database queries.
  #
  # This optimized version uses MongoDB aggregation pipelines to:
  # 1. Extract ALL file IDs from ALL places' ucf_lists in ONE operation
  # 2. Find which file IDs don't exist in Freereg1CsvFile collection
  # 3. Report/fix orphans without iterating individual places
  #
  # PERFORMANCE:
  # - Old approach: 10,000 places × 2 queries = 20,000 queries
  # - New approach: 1 aggregation pipeline + 1 existence check = 2 operations
  # - Speedup: 100-1000x faster for detecting file orphans
  #
  # USAGE:
  #   # Dry run (report only)
  #   rake ucf:validate_ucf_lists_optimized
  #
  #   # Fix issues
  #   rake ucf:validate_ucf_lists_optimized[true]
  #
  # ============================================================================
  desc "Detect orphaned UCF file IDs using MongoDB aggregation (optimized)"
  task :validate_ucf_lists_optimized, [:fix] => :environment do |t, args|
    # === STEP 1: Parse arguments ===
    # args[:fix] is a string from command line, convert to boolean
    # "true" or "fix" means apply fixes, anything else = dry run only
    apply_fixes = args[:fix].to_s.downcase.match?(/^(true|fix|yes|1)$/)

    puts "\n[UCF:OPTIMIZED] Starting optimized UCF validation..."
    puts "[UCF:OPTIMIZED] Fix mode: #{apply_fixes ? 'ENABLED' : 'DRY RUN'}"

    # === STEP 2: Extract ALL unique file IDs using MongoDB aggregation ===
    #
    # WHAT THIS DOES:
    # We want to find every unique file ID that appears in ANY place's ucf_list.
    # Instead of looping through places, we use MongoDB's aggregation pipeline.
    #
    # The pipeline works like an assembly line:
    # Stage 1: $project  → Extract the ucf_list field
    # Stage 2: $objectToArray → Convert {file1: [...], file2: [...]} to [{k: file1, v: [...]}, ...]
    # Stage 3: $unwind → Explode array into individual documents
    # Stage 4: $group → Collect unique file IDs (discard duplicates)
    # Result: Array of unique file IDs
    #
    # Example transformation:
    #   Before: {ucf_list: {file_1: [r1, r2], file_2: [r3]}}
    #   After: [{_id: file_1}, {_id: file_2}]
    #

    puts "[UCF:OPTIMIZED] Building aggregation pipeline..."

    pipeline = [
      # Stage 1: Extract only the ucf_list field from each place
      # $project keeps specified fields (default: _id + specified)
      # Here: '_id' isn't used, but kept automatically
      { '$project' => { 'ucf_list' => 1 } },

      # Stage 2: Convert the ucf_list Hash into an array of key-value pairs
      # $objectToArray is: {file_id: values} → [{k: file_id, v: values}, ...]
      # "k" = key (file_id), "v" = value (array of record_ids)
      # Example: {file_1: [r1, r2]} → [{k: "file_1", v: [r1, r2]}]
      { '$project' => { 'file_pairs' => { '$objectToArray' => '$ucf_list' } } },

      # Stage 3: Unwrap the array of pairs into individual documents
      # $unwind takes [{k: f1, v: [...]}, {k: f2, v: [...]}]
      # And produces one document for each element
      # Example: [{k: "file_1", v: [...]}] becomes two documents
      { '$unwind' => '$file_pairs' },

      # Stage 4: Group by file ID, extracting the "k" (key) field
      # $group: _id is what we're grouping by (file_id here)
      # This naturally deduplicates file IDs
      # Example: 10,000 places reference file_1 → results in ONE document
      { '$group' => { '_id' => '$file_pairs.k' } },

      # Stage 5 (optional): Sort for consistent ordering in logs
      { '$sort' => { '_id' => 1 } }
    ]

    # === STEP 3: Execute aggregation on Place collection ===
    puts "[UCF:OPTIMIZED] Executing aggregation pipeline (extracting unique file IDs)..."
    start_time = Time.current

    # .collection gives us access to MongoDB driver directly
    # .aggregate(pipeline) returns a Mongo cursor
    all_referenced_file_ids = Place.collection.aggregate(pipeline)
                                   .map { |doc| doc['_id'].to_s }
                                   .to_set  # Convert to Set for O(1) lookups

    elapsed = (Time.current - start_time).round(2)
    puts "[UCF:OPTIMIZED] Aggregation completed in #{elapsed}s"
    puts "[UCF:OPTIMIZED] Found #{all_referenced_file_ids.size} unique file IDs in ucf_lists"

    # === STEP 4: Find which file IDs actually exist in Freereg1CsvFile ===
    puts "[UCF:OPTIMIZED] Checking which files actually exist..."

    # Batch query: Check all referenced file IDs at once
    # Returns only IDs that exist (fast with index on _id)
    existing_file_ids = Freereg1CsvFile.where(:id.in => all_referenced_file_ids.to_a)
                                       .pluck(:id)
                                       .map(&:to_s)
                                       .to_set

    # === STEP 5: Find orphaned file IDs ===
    # Orphaned = referenced in ucf_list but doesn't exist in Freereg1CsvFile
    orphaned_file_ids = all_referenced_file_ids - existing_file_ids

    puts "[UCF:OPTIMIZED] Found #{orphaned_file_ids.size} orphaned file IDs"

    if orphaned_file_ids.empty?
      puts "[UCF:OPTIMIZED] No orphaned files found. All good!"
      next  # Exit task early
    end

    # === STEP 6: Report orphaned file IDs ===
    orphaned_file_ids.each do |file_id|
      puts "  - Orphaned file: #{file_id}"
    end

    # === STEP 7: Fix orphaned files (if requested) ===
    if apply_fixes
      puts "\n[UCF:OPTIMIZED] FIXING orphaned file IDs..."

      # Build MongoDB update document:
      # For each orphaned file_id, we create: "ucf_list.{file_id}" => 1 (to unset)
      # This tells MongoDB: "Remove this field from every document"
      #
      # Example: For file_1 and file_2:
      # { '$unset' => { 'ucf_list.file_1' => '', 'ucf_list.file_2' => '' } }
      #
      # This is efficient because:
      # 1. Single MongoDB operation (not per-place update)
      # 2. Uses $unset which only touches affected documents
      # 3. Atomic at MongoDB level
      #

      unset_fields = orphaned_file_ids.each_with_object({}) do |file_id, hash|
        # Key format: "ucf_list.{file_id}" removes that specific key
        # Value: '' (empty string) tells MongoDB to unset this field
        hash["ucf_list.#{file_id}"] = ''
      end

      puts "[UCF:OPTIMIZED] Removing #{orphaned_file_ids.size} orphaned file entries from all places..."

      start_time = Time.current

      # Execute atomic update on Place collection:
      # $unset operator removes fields from documents
      # {} as filter means "apply to all documents"
      result = Place.collection.update_many(
        {},  # Filter: update ALL places (no filter)
        { '$unset' => unset_fields }
      )

      elapsed = (Time.current - start_time).round(2)

      # Report results
      puts "[UCF:OPTIMIZED] Update completed in #{elapsed}s"
      puts "[UCF:OPTIMIZED] Modified documents: #{result.modified_count}"

      if result.modified_count > 0
        puts "[UCF:OPTIMIZED] ✓ Successfully removed #{orphaned_file_ids.size} orphaned file IDs"
      else
        puts "[UCF:OPTIMIZED] ! No places were updated (orphaned files may already be removed)"
      end
    else
      # Dry run mode: just report
      puts "\n[UCF:OPTIMIZED] DRY RUN MODE - No changes applied"
      puts "[UCF:OPTIMIZED] To fix these issues, run:"
      puts "[UCF:OPTIMIZED]   rake ucf:validate_ucf_lists_optimized[true]"
    end

    puts "[UCF:OPTIMIZED] Task complete.\n"
  end

  # old rake task
  # desc "Refresh UCF lists on places"
  # task :refresh_ucf_lists, [:skip, :sleep_time] => [:environment] do |t,args|

  #   file_for_messages = 'log/refresh_ucf_lists.log'
  #   message_file = File.new(file_for_messages, 'w')
  #   p "starting with a skip of #{args.skip.to_i}"
  #   message_file.puts "starting with a skip of #{args.skip.to_i}"
  #   time_start = Time.now

  #   Place.data_present.order(:chapman_code => :asc, :place_name => :asc).no_timeout.each_with_index do |place, i|
  #     time_place_start = Time.now

  #     unless args.skip && i < args.skip.to_i
  #       place.ucf_list = {}
  #       Freereg1CsvFile.where(:place_name => place.place_name).order(:file_name => :asc).all.no_timeout.each do |file|
  #         next if file.file_name == 'SOMFSJBA.csv' && file.userid == 'YvonneScrivener' # This file has 48,000 entries
  #         print "#{i}\tUpdating\t#{place.chapman_code}\t#{place.place_name}\t#{file.file_name}\n"
  #         message_file.puts "#{i}\tUpdating\t#{place.chapman_code}\t#{place.place_name}\t#{file.file_name}\n"
  #         place.update_ucf_list(file)
  #         file.save
  #       end
  #       place.save!
  #       sleep args.sleep_time.to_f
  #     end

  #     time_place_process = Time.now - time_place_start
  #     place_time = (Time.now - time_start) / i unless i == 0
  #     p " #{time_place_process}, #{place_time}, #{i}"
  #     message_file.puts "#{time_place_process}, #{place_time}, #{i}"

  #   end

  #   time_process = Time.now - time_start
  #   p " #{time_process}"
  #   message_file.puts "#{time_process}"
  # end

  # ============================================================================
  # Task name: freereg:refresh_ucf_lists - verbose, slow
  # Arguments:
  #   skip       → how many places to skip at the start
  #   sleep_time → pause between processing places
  # 
  # This rake task **refreshes the UCF lists** (Uncertain Character Format lists) for each `Place`. 
  # It rebuilds them from scratch by scanning all `Freereg1CsvFile` records belonging to that place.
  #    
  # rake ucf:refresh_ucf_lists
  # 
  # rake ucf:refresh_ucf_lists[0, 0.5]
  # 
  # ============================================================================
  desc "Refresh UCF lists on places"
  task :refresh_ucf_lists, [:skip, :sleep_time] => [:environment] do |t, args|

    # Default arguments
    args.with_defaults(skip: 0, sleep_time: 0)

    # Setup log file
    log_path = Rails.root.join("log", "refresh_ucf_lists.log")
    message_file = File.open(log_path, "w")

    Rails.logger.info "Starting refresh_ucf_lists with skip=#{args.skip}, sleep_time=#{args.sleep_time}"
    message_file.puts "Starting refresh_ucf_lists with skip=#{args.skip}, sleep_time=#{args.sleep_time}"

    time_start = Time.now

    # Iterate through all places with data_present field == true, 
    # ordered by county (chapman_code) and place name
    Place.data_present.order(chapman_code: :asc, place_name: :asc).no_timeout.each_with_index do |place, i|
      time_place_start = Time.now

      # Skip initial places if skip argument is set
      if i < args.skip.to_i
        Rails.logger.debug "Skipping place ##{i}: #{place.place_name}"
        next
      end

      # Reset place UCF list hash
      place.ucf_list = {}

      #  Iterate through all Freereg1CsvFile files belonging to this place
      Freereg1CsvFile.where(place_name: place.place_name).order(file_name: :asc).no_timeout.each do |file|
        # Special case: skip known heavy file
        # if file.file_name == "SOMFSJBA.csv" && file.userid == "YvonneScrivener"  # This file has 48,000 entries
        #   Rails.logger.warn "Skipping heavy file #{file.file_name} for user #{file.userid}"
        #   next
        # end

        # Log progress
        msg = "#{i}\tUpdating\t#{place.chapman_code}\t#{place.place_name}\t#{file.file_name}"
        Rails.logger.info msg
        message_file.puts msg
        message_file.flush
        puts "#{msg}"

        # Update UCF list with this Place's Freereg1CsvFile file
        begin
          place.update_ucf_list(file)
          place.ucf_list[file.id.to_s] ||= [] 
          file.save!
        rescue => e
          Rails.logger.error "Error updating file #{file.file_name} for place #{place.place_name}: #{e.message}"
          ap e.backtrace.take(5) # show first 5 lines of backtrace
        end
      end

      # Save updated place
      begin
        place.save!
      rescue => e
        Rails.logger.error "Error saving place #{place.place_name}: #{e.message}"
      end

      # Sleep between place iterations
      sleep args.sleep_time.to_f if args.sleep_time.to_f > 0

      # Place timing info
      time_place_process = Time.now - time_place_start
      avg_time = (Time.now - time_start) / i unless i.zero?

      Rails.logger.debug "Processed place ##{i} in #{time_place_process.round(2)}s (avg #{avg_time&.round(2)}s)"
      message_file.puts "Place process time: #{time_place_process}, Average time: #{avg_time}, Processed places: #{i + 1}"
    end

    # Final timing
    total_time = Time.now - time_start
    Rails.logger.info "Finished refresh_ucf_lists in #{total_time.round(2)}s"
    message_file.puts "Total finished refresh_ucf_lists time: #{total_time.round(2)}s"

    message_file.close
  end

end