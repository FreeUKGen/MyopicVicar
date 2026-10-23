desc 'Dry run: report how duplicate registers (same church and register type) would be merged, e.g. rake merge_duplicate_registers[SOM,10]. Changes no data.'
task :merge_duplicate_registers, [:chapman_code, :limit] => [:environment] do |_t, args|
  p 'Starting duplicate register dry run'
  report, summary = DuplicateRegisterMerger.new(chapman_code: args.chapman_code.presence, limit: args.limit).run
  summary.sort.each { |decision, count| p "#{decision}: #{count}" }
  p "Finished; report written to #{report}"
end
