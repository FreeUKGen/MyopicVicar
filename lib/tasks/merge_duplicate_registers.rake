desc 'Merge duplicate registers (same church and register type). Dry run unless mode is apply, ' \
     'e.g. rake merge_duplicate_registers[dry_run,SOM,10] or rake merge_duplicate_registers[apply]'
task :merge_duplicate_registers, [:mode, :chapman_code, :limit] => [:environment] do |_t, args|
  apply = args.mode == 'apply'
  p "Starting duplicate register #{apply ? 'merge' : 'dry run'}"
  report, summary = DuplicateRegisterMerger.new(apply: apply, chapman_code: args.chapman_code.presence, limit: args.limit).run
  summary.sort.each { |decision, count| p "#{decision}: #{count}" }
  p "Finished; report written to #{report}"
end
