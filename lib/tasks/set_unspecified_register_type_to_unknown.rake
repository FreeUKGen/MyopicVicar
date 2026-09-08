namespace :freereg do
  # One-off cleanup for #3013. When a transcriber did not specify a register type
  # it was stored with a blank code (" " or ""), which displays as "Unspecified"
  # and prevents register matching on re-upload. Give those registers the explicit
  # "Unknown" (UK) type.
  #
  # Register#change_type propagates the new type to the register's files, entries
  # and search-record location names.
  #
  #   rake freereg:set_unspecified_register_type_to_unknown          # dry run
  #   rake freereg:set_unspecified_register_type_to_unknown[apply]   # make the change
  task :set_unspecified_register_type_to_unknown, [:apply] => :environment do |_t, args|
    apply = args.apply == 'apply'
    log_path = Rails.root.join('log', 'set_unspecified_register_type_to_unknown.log')
    FileUtils.mkdir_p(File.dirname(log_path))
    log = File.new(log_path, 'w')
    started = Time.now
    log.puts "started #{started} (#{apply ? 'APPLY' : 'DRY RUN'})"

    scope = Register.where(:register_type.in => [' ', '', nil])
    total = scope.count
    message = "#{total} register(s) with an unspecified register type"
    log.puts message
    puts message

    changed = 0
    errored = 0
    scope.no_timeout.each_with_index do |register, i|
      church = register.church
      label = "#{church&.place&.place_name} / #{church&.church_name} (register #{register.id})"

      if church.nil?
        log.puts "SKIP #{label} - no church"
        next
      end

      unless apply
        log.puts "would change #{label} (#{register.freereg1_csv_files.count} file(s))"
        next
      end

      begin
        register.change_type('UK')
        if register.errors.any?
          errored += 1
          log.puts "ERROR #{label} - #{register.errors.full_messages.join('; ')}"
        else
          changed += 1
          log.puts "OK    #{label}"
        end
      rescue StandardError => e
        errored += 1
        log.puts "ERROR #{label} - #{e.class}: #{e.message}"
      end

      puts "[#{i + 1}/#{total}] #{label}" if ((i + 1) % 50).zero?
    end

    summary = apply ? "changed #{changed} register(s), #{errored} error(s)" : 'dry run only - re-run with [apply] to make changes'
    log.puts summary
    log.puts "elapsed #{Time.now - started}s"
    log.close
    puts "done - #{summary}"
    puts "see #{log_path}"
  end
end
