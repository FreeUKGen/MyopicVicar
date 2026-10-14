require 'set'

task :correct_all_emendations,[:limit,:fix,:reset,:since] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/correct_all_emendation.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "w")
  #type true for original and false for replacement
  args.fix == "true" ? fix = true : fix = false

  # checkpoint file: the _id of the last record this task has examined, so a later invocation can
  # resume the single pass over the backlog (see below) instead of rescanning from the start.
  # A checkpoint left by the old per-rule format (a plain integer, not an ObjectId string) isn't
  # a legal ObjectId, so it reads as "no checkpoint" here -- a safe restart under this algorithm.
  # pass reset=true to ignore/clear an existing checkpoint and start over from the beginning.
  progress_file = "#{Rails.root}/tmp/correct_all_emendations_progress.txt"
  File.delete(progress_file) if args.reset == "true" && File.exist?(progress_file)
  resume_last_id = nil
  if File.exist?(progress_file)
    saved = File.read(progress_file).strip
    resume_last_id = BSON::ObjectId.from_string(saved) if BSON::ObjectId.legal?(saved)
  end

  # optional :since arg (e.g. '2026-05-01') scopes the fix to SearchRecords CREATED on or after
  # that date, so we only touch the backlog of records added while emendations were broken
  # instead of rescanning the entire historical collection (older records were already emended
  # when they were built).
  begin
    since_time = args.since.present? ? Time.zone.parse(args.since) : nil
  rescue ArgumentError
    abort "correct_all_emendations: could not parse since='#{args.since}' (use e.g. 2026-05-01)"
  end
  abort "correct_all_emendations: since='#{args.since}' is not a valid date (use e.g. 2026-05-01)" if args.since.present? && since_time.nil?
  # _id embeds a creation timestamp and is covered by the default (always-present) _id index --
  # unlike the `c_at` field, which isn't indexed at all. Filtering on `c_at` forced Mongo to walk
  # every record matching a name across the WHOLE historical collection before rejecting the old
  # ones as a residual, unindexed check; filtering on _id instead bounds the scan itself to the
  # actual backlog created since this date (confirmed via explain(): totalDocsExamined dropped
  # from "every record ever with this name" to just the ~800k-record recent backlog).
  since_object_id = since_time ? BSON::ObjectId.from_time(since_time) : nil
  # a resumed run must never start earlier than the since-boundary
  start_id = [resume_last_id, since_object_id].compact.max

  output_file.puts "Starting correction of original emendations at #{Time.now}" \
    "#{start_id ? " (starting after _id=#{start_id})" : ""}" \
    "#{since_time ? " (scoped to records created since #{since_time})" : ""}"

  stopping = args.limit.to_i
  total_num_emended = 0
  total_num_unemended = 0
  num = 0
  hit_limit = false
  retries = 0
  MAX_RETRIES = 10

  # fixes are sent as bulk writes of write_batch records (one round trip each) instead of a save
  # per record; the checkpoint only moves on once the writes for the records before it are sent
  write_batch = 500
  pending = []
  flush_writes = lambda do |checkpoint_id|
    if pending.any?
      SearchRecord.collection.bulk_write(pending, ordered: false)
      pending.clear
      sleep(Rails.application.config.sleep.to_f)
    end
    # only a fix run moves the checkpoint, so a report run can't make a later fix run skip records
    File.write(progress_file, checkpoint_id.to_s) if fix && checkpoint_id
  end

  # Every rule a record needs is applied to it in a single pass over the backlog, instead of the
  # previous approach of running one query per rule over the *whole* backlog -- with 2500+ rules,
  # that meant rescanning the same several-hundred-thousand-record backlog 2500+ times over, just
  # to find the handful of matches for each individual name. Emendor.emend already looks up every
  # rule that applies to a record's names in one call, so one pass here is all that's needed.
  originals = EmendationRule.distinct(:original)
  p "Ready: #{originals.size} distinct original names across #{EmendationRule.all.count} rules, starting after _id=#{start_id} at #{Time.now}"

  SearchRecord.with(socket_timeout: 600, connect_timeout: 600) do
    last_id = start_id
    begin
      # only records that contain at least one of the known "original" names can possibly need a
      # fix -- pushing this down means Mongo never ships an irrelevant record to Ruby.
      scope = SearchRecord.where(:"search_names.first_name".in => originals).no_timeout.asc(:_id)
      scope = scope.where(:_id.gt => last_id) if last_id
      # always drive this off the _id index: it's what bounds the scan to the recent backlog,
      # and it's what makes the checkpoint above meaningful (records are visited in _id order).
      scope = scope.hint(_id: 1)
      scope = scope.batch_size(20)
      scope = scope.limit([stopping - num, 1].max) if stopping > 0

      scope.each do |record|
        # Emendor.emend unconditionally appends a newly-built emended name for every matching
        # rule -- calling it on a record that was already (fully or partially) fixed by an
        # earlier run re-adds the same emended names again. Keep only the emended names whose
        # content (ignoring the embedded doc's own _id, which is always fresh) isn't on the record
        # yet, so re-running this task is idempotent; the existing names are never rewritten.
        seen = Set.new(record.search_names.map { |name| name.attributes.except('_id') })
        new_names = Emendor.emend(record.search_names).drop(record.search_names.size).select do |name|
          seen.add?(name.attributes.except('_id'))
        end

        if new_names.any?
          if fix
            pending << { update_one: { filter: { _id: record._id },
                                       update: { '$push' => { search_names: { '$each' => new_names.map(&:as_document) } } } } }
            output_file.puts "#{record._id} entry #{record.freereg1_csv_entry_id} added #{new_names.map(&:first_name).join(', ')}"
          end
          total_num_unemended += 1
        else
          total_num_emended += 1
        end

        last_id = record._id
        flush_writes.call(last_id) if pending.size >= write_batch
        num += 1
        sleep(1) if num % 100_000 == 0
        if stopping > 0 && num >= stopping
          hit_limit = true
          break
        end
      end
    rescue Mongo::Error::SocketTimeoutError => e
      retries += 1
      if retries <= MAX_RETRIES
        p "Timed out (retry #{retries}/#{MAX_RETRIES}, resuming after _id=#{last_id}) at #{Time.now}: #{e.message}"
        retry
      else
        raise
      end
    end
    flush_writes.call(last_id)
  end
  # ran to completion without hitting the limit -- nothing left to resume, clear the checkpoint
  File.delete(progress_file) if fix && !hit_limit && File.exist?(progress_file)
  p "  A total of #{num} records examined with #{total_num_emended} already emended and #{total_num_unemended} #{fix ? 'emended' : 'needing emendation'} at #{Time.now}"
end
